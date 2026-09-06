# Validação em dispositivos

## Status

Validação física Android e iOS concluída de forma satisfatória em 2026-09-06,
incluindo o fluxo principal, acessibilidade, texto ampliado e o roteiro das
telas do aplicativo. As próximas validações físicas serão regressivas, feitas
quando houver alterações relevantes na interface ou no desempenho.

## Android

1. Execute `flutter devices` e selecione um aparelho físico.
2. Execute `flutter run -d <id> --profile`.
3. Verifique desbloqueio, Bancada, Validação, Observatório, Projetos e Documentação.
4. Importe CSV, execute backtesting, calibre a faixa e salve uma observação.
5. Repita com fonte ampliada e TalkBack.

## iOS

1. Em macOS, execute `flutter pub get` e abra `ios/Runner.xcworkspace` no Xcode.
2. Selecione um aparelho físico e execute o esquema Runner em Profile.
3. Repita o roteiro Android com VoiceOver e texto ampliado.

Registre modelo do aparelho, sistema, versão do app, tempo de inicialização,
tempo de cálculo, memória percebida, falhas e screenshots. Resultados deste
checklist não devem ser tratados como cobertura automatizada.