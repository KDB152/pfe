import 'package:flutter/material.dart';

class AppSizes {
  // Obtenir la taille de l'écran
  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;
  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  // Calcul adaptatif basé sur la largeur de l'écran
  static double width(BuildContext context, double percentage) =>
      screenWidth(context) * percentage;
  static double height(BuildContext context, double percentage) =>
      screenHeight(context) * percentage;

  // Tailles pour les éléments d'UI
  static double buttonHeight(BuildContext context) =>
      height(context, 0.07); // 7% de la hauteur d'écran
  static double iconSize(BuildContext context) =>
      width(context, 0.15); // 15% de la largeur d'écran
  static double contentPadding(BuildContext context) =>
      width(context, 0.05); // 5% de la largeur d'écran

  // Police
  static double titleFontSize(BuildContext context) =>
      width(context, 0.06); // 6% de la largeur
  static double subtitleFontSize(BuildContext context) =>
      width(context, 0.04); // 4% de la largeur
  static double bodyFontSize(BuildContext context) =>
      width(context, 0.035); // 3.5% de la largeur
}
