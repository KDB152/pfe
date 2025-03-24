// functions/index.js

const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// Fonction pour supprimer un utilisateur Firebase Auth (admin seulement)
exports.deleteUser = functions.https.onCall(async (data, context) => {
  // Vérifier si l'appelant est authentifié
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Vous devez être connecté pour effectuer cette action.'
    );
  }

  // Vérifier si l'appelant est un admin
  const callerUid = context.auth.uid;
  const callerRef = admin.firestore().collection('users').doc(callerUid);
  const callerDoc = await callerRef.get();
  
  if (!callerDoc.exists || !callerDoc.data().isAdmin) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Seuls les administrateurs peuvent supprimer des utilisateurs.'
    );
  }

  // Vérifier que l'UID à supprimer a été fourni
  const uid = data.uid;
  if (!uid) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'L\'identifiant utilisateur (uid) est requis.'
    );
  }

  try {
    // Supprimer l'utilisateur de Firebase Auth
    await admin.auth().deleteUser(uid);
    
    return { success: true, message: "Utilisateur supprimé avec succès" };
  } catch (error) {
    console.error("Erreur lors de la suppression de l'utilisateur:", error);
    throw new functions.https.HttpsError(
      'internal',
      `Erreur lors de la suppression de l'utilisateur: ${error.message}`
    );
  }
});