import 'package:flutter/material.dart';
import 'package:tournament_app/core/theme/app_colors.dart';
import 'package:tournament_app/core/theme/app_typography.dart';
import 'package:tournament_app/core/theme/app_theme.dart';

class CreamScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool useGradient;
  final bool resizeToAvoidBottomInset;

  const CreamScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.useGradient = true,
    this.resizeToAvoidBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      body: useGradient
          ? Container(
              decoration: const BoxDecoration(
                gradient: AppColors.creamGradient,
              ),
              child: body,
            )
          : body,
    );
  }
}
