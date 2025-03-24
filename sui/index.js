const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");

// Fichier à créer dans votre projet Firebase Cloud Functions
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.deleteUserAuth = functions.https.onCall(async (data, context) => {
  // Vérifier si la requête provient d'un admin
  const callerUid = context.auth.uid;
  const callerData = await admin.firestore().collection('users').doc(callerUid).get();
  
  if (!callerData.exists || !callerData.data().isAdmin) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Seuls les administrateurs peuvent supprimer des comptes utilisateurs.'
    );
  }

  // Vérifier que l'UID à supprimer a été fourni
  if (!data.uid) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'L\'UID de l\'utilisateur à supprimer est requis.'
    );
  }

  try {
    // Supprimer l'utilisateur de Firebase Authentication
    await admin.auth().deleteUser(data.uid);
    
    // Vous pouvez aussi ajouter ici d'autres opérations de nettoyage
    // comme supprimer les données associées à cet utilisateur dans d'autres collections
    
    return { success: true };
  } catch (error) {
    console.error('Erreur lors de la suppression de l\'utilisateur:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Erreur lors de la suppression de l\'utilisateur.',
      error
    );
  }
});