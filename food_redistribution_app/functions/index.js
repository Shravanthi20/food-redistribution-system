const functions = require("firebase-functions");
const admin = require("firebase-admin");
const geofire = require("geofire-common");

admin.initializeApp();
const db = admin.firestore();

// --- Configuration / Constants ---
const ASSIGNMENT_TIMEOUT_MINS = 30;
const MAX_SEARCH_RADIUS_KM = 20;
const MAX_REASSIGNMENT_ATTEMPTS = 5;

// Firebase Schema v2.0 Collection Names
const Collections = {
    users: "users",
    organizations: "organizations",
    donations: "donations",
    deliveries: "deliveries",
    requests: "requests",
    assignments: "assignments",
    tracking: "tracking",
    notifications: "notifications",
    verifications: "verifications",
    audit: "audit",
    security: "security",
    analytics: "analytics",
    matching: "matching",
    adminTasks: "admin_tasks",
    system: "system",
};

const WEIGHTS = {
    DISTANCE: 0.4,
    WASTE_RISK: 0.3,
    NGO_NEED: 0.2, // 1 - NeedLevel
    FAIRNESS: 0.1  // Starvation penalty
};

/**
 * Trigger: When a new Food Donation is created.
 * Goal: Find best NGO candidates and soft-lock the top one.
 */
exports.onDonationCreated = functions.firestore
    .document("donations/{donationId}")
    .onCreate(async (snap, context) => {
        const donation = snap.data();
        const donationId = context.params.donationId;

        if (donation.status !== "listed") return null;

        try {
            // Input Validation
            if (!isValidLocation(donation.pickupLocation)) {
                console.error(`Invalid location for donation ${donationId}`);
                await snap.ref.update({ matchingStatus: "failed_invalid_location" });
                return null;
            }

            // 1. Calculate Urgency Score
            const urgencyScore = calculateUrgency(donation);

            // Update donation with score
            await snap.ref.update({ urgencyScore });

            // 2. Find Candidates (Geo-Query)
            const candidates = await findBestNGOCandidates(donation, urgencyScore);

            if (candidates.length === 0) {
                console.log(`No matching NGOs found for donation ${donationId}`);
                await snap.ref.update({ matchingStatus: "no_match_found" });
                return null;
            }

            // 3. Assign to Top Candidate (Soft-Lock)
            const topCandidate = candidates[0];
            await createAssignment(donationId, topCandidate, "NGO_OFFER");

            console.log(`Assigned donation ${donationId} to NGO ${topCandidate.id} with score ${topCandidate.score}`);

            return null;
        } catch (error) {
            console.error("Error in onDonationCreated:", error);
            return null;
        }
    });

/**
 * Trigger: When an NGO accepts the donation (assignment created and accepted).
 * Goal: Find best Volunteer.
 */
exports.onDonationAccepted = functions.firestore
    .document("assignments/{assignmentId}")
    .onCreate(async (snap, context) => {
        const assignment = snap.data();
        
        // Only process when this is an NGO acceptance type
        if (assignment.type !== "NGO_OFFER" || assignment.status !== "accepted") return null;
        
        const { donationId, assigneeId: ngoId } = assignment;

        try {
            // Fetch full donation and organization details
            const donationSnap = await db.collection(Collections.donations).doc(donationId).get();
            const donation = donationSnap.data();
            const orgSnap = await db.collection(Collections.organizations).doc(ngoId).get();
            const ngo = orgSnap.data();

            // Volunteer Matching Logic
            const volunteers = await findBestVolunteers(donation, ngo);

            if (volunteers.length === 0) {
                console.log(`No volunteers found for donation ${donationId}`);
                await db.collection(Collections.donations).doc(donationId).update({ matchingStatus: "pending_volunteer_manual" });
                return null;
            }

            const topVolunteer = volunteers[0];
            await createAssignment(donationId, topVolunteer, "VOLUNTEER_TASK");

            return null;
        } catch (error) {
            console.error("Error in onDonationAccepted:", error);
            return null;
        }
    });

/**
 * Trigger: Periodic cleanup or Specific Rejection Event.
 * Implements Self-Healing Loop.
 */
exports.onAssignmentUpdate = functions.firestore
    .document("assignments/{assignmentId}")
    .onUpdate(async (change, context) => {
        const newData = change.after.data();
        const previousData = change.before.data();

        // If status changed to REJECTED or EXPIRED
        if (
            (newData.status === "rejected" || newData.status === "expired") &&
            previousData.status === "pending"
        ) {
            const { donationId, type } = newData;
            console.log(`Assignment ${context.params.assignmentId} failed. Triggering reassignment for ${donationId}`);

            if (type === "NGO_OFFER") {
                await reassignNGO(donationId);
            } else if (type === "VOLUNTEER_TASK") {
                await reassignVolunteer(donationId);
            }
        }
    });

// --- Helper Functions ---

function calculateUrgency(donation) {
    if (!donation.expiresAt) return 0.5; // Default metric

    const now = admin.firestore.Timestamp.now().toDate();
    const expiry = donation.expiresAt.toDate ? donation.expiresAt.toDate() : new Date(donation.expiresAt);

    const hoursUntilExpiry = (expiry - now) / (1000 * 60 * 60);

    if (hoursUntilExpiry <= 4) return 1.0;
    if (hoursUntilExpiry <= 24) return 0.8;
    if (hoursUntilExpiry <= 48) return 0.5;
    return 0.2;
}

// SCALABLE GEO-QUERY IMPLEMENTATION
async function findBestNGOCandidates(donation, urgencyScore) {
    if (!isValidLocation(donation.pickupLocation)) return [];

    const center = [donation.pickupLocation.latitude, donation.pickupLocation.longitude];
    const radiusInM = MAX_SEARCH_RADIUS_KM * 1000;

    // 1. Get Geohash Bounds
    const bounds = geofire.geohashQueryBounds(center, radiusInM);

    // 2. Parallel Queries
    const promises = [];
    for (const b of bounds) {
        const q = db.collection(Collections.organizations)
            .where("isVerified", "==", true)
            .orderBy("location.geohash")
            .startAt(b[0])
            .endAt(b[1]);
        promises.push(q.get());
    }

    // 3. Aggregate Results
    const snapshots = await Promise.all(promises);
    const validNGOs = [];

    for (const snap of snapshots) {
        for (const doc of snap.docs) {
            const ngo = doc.data();
            ngo.id = doc.id;

            if (!isValidLocation(ngo.location)) continue;

            const ngoLat = ngo.location.latitude;
            const ngoLng = ngo.location.longitude;

            // Filter false positives from bounding box
            const distanceInKm = geofire.distanceBetween([ngoLat, ngoLng], center);
            const distanceInM = distanceInKm * 1000;

            if (distanceInM <= radiusInM) {
                // Hard Constraints
                // a. Capacity
                if (ngo.capacity < donation.quantity) continue;

                // b. Food Type
                if (ngo.preferredFoodTypes && ngo.preferredFoodTypes.length > 0 && donation.foodTypes) {
                    const hasMatch = donation.foodTypes.some(type => ngo.preferredFoodTypes.includes(type));
                    if (!hasMatch) continue;
                }

                validNGOs.push({ ...ngo, distanceKm: distanceInKm });
            }
        }
    }

    // Cost Function / Scoring
    const candidates = [];
    for (const ngo of validNGOs) {
        const normDistance = 1 - (ngo.distanceKm / MAX_SEARCH_RADIUS_KM);
        const normNeed = 0.5; // Placeholder

        // Improved Cost Function
        const score = (
            (WEIGHTS.DISTANCE * normDistance) +
            (WEIGHTS.WASTE_RISK * urgencyScore) +
            (WEIGHTS.NGO_NEED * normNeed)
        );

        candidates.push({ id: ngo.id, score });
    }

    // Sort by Score Descending
    return candidates.sort((a, b) => b.score - a.score);
}

const MAX_BATCH_SIZE = 3;

async function findBestVolunteers(donation, ngo) {
    // 1. Fetch Volunteer Candidates (role=volunteer, status=active)
    // Volunteers now have embedded profiles in users collection
    const volSnapshot = await db.collection(Collections.users)
        .where("role", "==", "volunteer")
        .where("status", "==", "active")
        .get();

    const candidates = [];

    for (const doc of volSnapshot.docs) {
        const user = doc.data();
        const vol = { id: doc.id, ...user, ...user.profile }; // Merge profile data

        // Check location (can be in profile or root)
        const location = vol.profile?.location || vol.location;
        if (!isValidLocation(location)) continue;
        vol.location = location;

        // Hard Constraint: Vehicle (from embedded profile)
        const hasVehicle = vol.profile?.hasVehicle || vol.hasVehicle;
        const vehicleType = vol.profile?.vehicleType || vol.vehicleType;
        
        if (donation.quantity > 20 && !hasVehicle) continue;
        if (donation.requiresRefrigeration && vehicleType !== "refrigerated_truck" && vehicleType !== "car") continue;

        // [NEW] Hard Constraint: Time Availability
        if (!isVolunteerAvailableNow(vol)) continue;

        // BATCHING / VRP Logic
        // Determine active tasks (Is this person busy?)
        const activeTasksSnap = await db.collection(Collections.assignments)
            .where("assigneeId", "==", vol.id)
            .where("status", "in", ["pending", "accepted", "picked_up"])
            .get();

        const activeTaskCount = activeTasksSnap.size;

        // Capacity Constraint
        if (activeTaskCount >= MAX_BATCH_SIZE) continue;

        let detourKm = 0;
        let isEnRoute = false;

        if (activeTaskCount > 0) {
            // DETOUR CALCULATION
            // Assumption: If they are active and delivering to SAME NGO, they effectively bundle.
            // For V1, we blindly trust "En Route" if they are assigned to this NGO already.
            // A more complex check would query the donation details of their active tasks.
            // Here, we calculate detour assuming the current trip (Vol -> NGO) becomes (Vol -> New -> NGO).

            isEnRoute = true;

            const distToNGO = calculateDistance(vol.location, ngo.location);
            const distToNew = calculateDistance(vol.location, donation.pickupLocation);
            const distNewToNGO = calculateDistance(donation.pickupLocation, ngo.location);

            detourKm = (distToNew + distNewToNGO) - distToNGO;
        }

        // Search Radius Constraint (Applicable if not en-route batching)
        const distToDonor = calculateDistance(vol.location, donation.pickupLocation);
        if (distToDonor > 15 && !isEnRoute) continue;

        // Score Calculation
        let score = (1 / (distToDonor + 1));

        // Batching Bonus
        if (isEnRoute) {
            if (detourKm < 5) {
                // High bonus for small detour
                score += (5 - detourKm) * 0.5;
            } else {
                continue; // Detour too large
            }
        } else {
            // Fairness: Penalize strictly busy people if not batching
            if (activeTaskCount > 0) score *= 0.5;
        }

        candidates.push({ id: vol.id, score });
    }

    return candidates.sort((a, b) => b.score - a.score);
}

async function createAssignment(donationId, candidate, type) {
    const expiresAt = new Date();
    expiresAt.setMinutes(expiresAt.getMinutes() + ASSIGNMENT_TIMEOUT_MINS);

    await db.collection(Collections.assignments).add({
        donationId,
        assigneeId: candidate.id,
        type,
        status: "pending",
        score: candidate.score,
        createdAt: admin.firestore.Timestamp.now(),
        expiresAt: admin.firestore.Timestamp.fromDate(expiresAt)
    });

    await db.collection(Collections.donations).doc(donationId).update({
        matchingStatus: type === "NGO_OFFER" ? "pending_ngo" : "pending_volunteer"
    });

    // Notify Assignee
    let title = "New Assignment";
    let body = "You have a new donation assignment.";

    if (type === "NGO_OFFER") {
        title = "New Donation Match";
        body = "We found a donation that matches your needs.";
    } else if (type === "VOLUNTEER_TASK") {
        title = "New Delivery Task";
        body = "You have been assigned to pick up a donation.";
    }

    await sendPushNotification(candidate.id, title, body, {
        donationId,
        type: "assignment",
        assignmentType: type
    });
}

async function reassignNGO(donationId) {
    const donationSnap = await db.collection(Collections.donations).doc(donationId).get();
    const donation = donationSnap.data();

    // 1. Retry Limit Check
    const assignmentsSnap = await db.collection(Collections.assignments)
        .where("donationId", "==", donationId)
        .where("type", "==", "NGO_OFFER")
        .get();

    const attempts = assignmentsSnap.size;

    if (attempts >= MAX_REASSIGNMENT_ATTEMPTS) {
        console.log(`Max Reassignment Attempts (${attempts}) reached for ${donationId}. Stopping.`);
        await db.collection(Collections.donations).doc(donationId).update({
            matchingStatus: "failed_max_retries",
            manualReviewRequired: true
        });
        return;
    }

    // 2. Exclude previous rejects
    const rejectedIds = assignmentsSnap.docs.map(d => d.data().assigneeId);

    // 3. Find next candidate
    const urgencyScore = donation.urgencyScore || calculateUrgency(donation);
    const allCandidates = await findBestNGOCandidates(donation, urgencyScore);

    const nextCandidate = allCandidates.find(c => !rejectedIds.includes(c.id));

    if (nextCandidate) {
        await createAssignment(donationId, nextCandidate, "NGO_OFFER");
        console.log(`Reassigned ${donationId} to next NGO ${nextCandidate.id} (Attempt ${attempts + 1})`);
    } else {
        console.log(`No more NGO candidates for ${donationId}.`);
        await db.collection(Collections.donations).doc(donationId).update({ matchingStatus: "failed_no_candidates" });
    }
}

async function reassignVolunteer(donationId) {
    // Similar reassignment logic for volunteers
    // ...
}

function isValidLocation(loc) {
    return loc &&
        typeof loc.latitude === 'number' &&
        typeof loc.longitude === 'number';
}

function calculateDistance(loc1, loc2) {
    if (!isValidLocation(loc1) || !isValidLocation(loc2)) return 9999;

    const lat1 = loc1.latitude;
    const lon1 = loc1.longitude;
    const lat2 = loc2.latitude;
    const lon2 = loc2.longitude;

    const R = 6371; // km
    const dLat = toRad(lat2 - lat1);
    const dLon = toRad(lon2 - lon1);
    const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) *
        Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
}

function toRad(value) {
    return value * Math.PI / 180;
}

async function getActiveTaskCount(volunteerId) {
    const snap = await db.collection(Collections.assignments)
        .where("assigneeId", "==", volunteerId)
        .where("status", "in", ["pending", "accepted"])
        .get();
    return snap.size;
}

function isVolunteerAvailableNow(vol) {
    // Check embedded profile or direct field
    const availabilityHours = vol.profile?.availabilityHours || vol.availabilityHours;
    if (!availabilityHours || availabilityHours.length === 0) return true; // Assume available if not set

    const now = new Date();
    const currentHour = now.getHours();
    const day = now.getDay(); // 0 = Sunday, 1 = Monday...

    // Check Weekends
    const isWeekend = (day === 0 || day === 6);
    if (availabilityHours.includes("Weekends") && isWeekend) return true;

    // Check Time Slots
    // "Morning (6AM-12PM)", "Afternoon (12PM-5PM)", "Evening (5PM-10PM)"

    if (availabilityHours.includes("Morning (6AM-12PM)") && (currentHour >= 6 && currentHour < 12)) return true;
    if (availabilityHours.includes("Afternoon (12PM-5PM)") && (currentHour >= 12 && currentHour < 17)) return true;
    if (availabilityHours.includes("Evening (5PM-10PM)") && (currentHour >= 17 && currentHour < 22)) return true;

    return false;
}

