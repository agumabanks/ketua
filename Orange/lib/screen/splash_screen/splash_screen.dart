import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ketua_ui/screen/splash_screen/splash_screen_view_model.dart';
import 'package:ketua_ui/utils/color_res.dart';
import 'package:ketua_ui/utils/ketua_theme.dart';
import 'package:stacked/stacked.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<SplashScreenViewModel>.reactive(
      onViewModelReady: (viewModel) => viewModel.init(),
      viewModelBuilder: () => SplashScreenViewModel(),
      builder: (context, viewModel, child) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // KETUA wordmark — UPPERCASE, real font weight 900, gradient.
                ShaderMask(
                  shaderCallback: (bounds) =>
                      KetuaTheme.brandGradient.createShader(bounds),
                  blendMode: BlendMode.srcIn,
                  child: Text(
                    KetuaTheme.brandName, // "KETUA"
                    textAlign: TextAlign.center,
                    style: KetuaTheme.brandWordmark(size: 48),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Meet. Vibe. Connect.',
                  style: TextStyle(
                    fontFamily: 'gilroy_medium',
                    fontSize: 15,
                    letterSpacing: 1,
                    color: ColorRes.textSecondaryDark,
                  ),
                ),
                if (viewModel.failed) ...[
                  const SizedBox(height: 28),
                  const Text('Unable to connect. Check your connection.'),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: viewModel.init, child: const Text('Retry')),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
