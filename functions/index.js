import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { getFirestore } from "firebase-admin/firestore";
import { initializeApp } from "firebase-admin/app";

initializeApp();
const db = getFirestore();

export const assignDriver = onDocumentCreated("orders/{orderId}", async (event) => {
  const order = event.data.data();
  const orderId = event.params.orderId;

  if (order.driverId !== null) return;

  const driversSnap = await db.collection("driver_locations").get();
  if (driversSnap.empty) return;

  const scores = [];

  driversSnap.forEach((doc) => {
    const d = doc.data();
    const distance = Math.sqrt(
      Math.pow(d.lat - 0, 2) + Math.pow(d.lng - 0, 2)
    );

    const urgency = order.urgencyScore || 0;

    const score = (1 / (distance + 0.001)) + urgency;

    scores.push({
      driverId: doc.id,
      score,
      distance,
      urgency,
    });
  });

  scores.sort((a, b) => b.score - a.score);
  const best = scores[0];

  await db.collection("orders").doc(orderId).update({
    driverId: best.driverId,
    status: "assigned",
    updatedAt: new Date(),
  });

  await db.collection("driver_assignment_logs").add({
    orderId,
    chosenDriver: best.driverId,
    scores,
    timestamp: new Date(),
  });
});
