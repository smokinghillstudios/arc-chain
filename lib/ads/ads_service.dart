import 'dart:async';
import 'dart:io';

import 'package:google_mobile_ads/google_mobile_ads.dart';

/// IDs do AdMob — ATENÇÃO: estes são os IDs DE TESTE oficiais do Google
/// (mesmos do ARCO). Antes de publicar, substitua pelos IDs reais da sua
/// conta AdMob (o APPLICATION_ID correspondente fica no AndroidManifest.xml).
const kAdMobRewardedUnitId = 'ca-app-pub-3940256099942544/5224354917';
const kAdMobBannerUnitId = 'ca-app-pub-3940256099942544/6300978111';

/// Anúncios no padrão do ARCO: rewarded (aqui, +toques quando o tabuleiro
/// trava) e banner no topo da tela de jogo. Os unit IDs de teste exibem
/// anúncios "Test Ad" reais; a simulação de contagem só entra como fallback
/// quando o vídeo não carrega (sem rede, por exemplo).
class AdsService {
  AdsService._();
  static final AdsService instance = AdsService._();

  static final bool _isTestEnv =
      Platform.environment.containsKey('FLUTTER_TEST');

  /// SDK disponível (fora do ambiente `flutter test`).
  bool get adsAvailable => !_isTestEnv;

  RewardedAd? _loaded;
  bool _initialized = false;

  /// Inicializa o SDK e pré-carrega o primeiro rewarded.
  Future<void> init() async {
    if (!adsAvailable || _initialized) return;
    _initialized = true;
    try {
      await MobileAds.instance.initialize();
      _preload();
    } catch (_) {
      // SDK indisponível: fluxos caem na simulação.
    }
  }

  void _preload() {
    RewardedAd.load(
      adUnitId: kAdMobRewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _loaded = ad,
        onAdFailedToLoad: (_) => _loaded = null,
      ),
    );
  }

  /// Mostra o rewarded real. Retorna true/false (recompensa ganha ou não)
  /// ou **null** quando não há anúncio disponível — o chamador deve usar a
  /// simulação de contagem como fallback.
  Future<bool?> showRewarded() async {
    if (!adsAvailable) return null;
    final ad = _loaded;
    if (ad == null) {
      _preload(); // tenta ter um pronto na próxima
      return null;
    }
    _loaded = null;
    var earned = false;
    final done = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!done.isCompleted) done.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        if (!done.isCompleted) done.complete();
      },
    );
    try {
      await ad.show(onUserEarnedReward: (_, _) => earned = true);
      await done.future;
    } catch (_) {
      return null;
    }
    _preload();
    return earned;
  }
}
