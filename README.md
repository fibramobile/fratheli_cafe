# Frathéli Cafés — Layout Premium em Flutter

Projeto Flutter completo da Frathéli Cafés, com interface responsiva para Web,
Android e iOS.

## Funcionalidades mantidas

- catálogo remoto de produtos, com vitrine local de segurança;
- cadastro, login e área do cliente;
- sacola com seleção de moagem e quantidade;
- cálculo de frete por CEP e quantidade de pacotes;
- criação do pedido e abertura do pagamento Pix;
- listagem de pedidos e status de pagamento e entrega;
- contador de visitas no rodapé;
- sincronização de pedidos já existente no `OrderService`.

## Executar

```bash
flutter pub get
flutter run -d chrome
```

Para gerar a versão web:

```bash
flutter build web --release
```

O resultado será criado em `build/web`.

## Arquivos principais

- `lib/views/home_page.dart`: página premium responsiva;
- `lib/views/widgets/cart_drawer.dart`: sacola, frete e checkout;
- `lib/views/meus_pedidos_page.dart`: histórico e status;
- `lib/views/order_details_page.dart`: detalhes, entrega e pagamento;
- `assets/premium/`: logo e fotografias do layout premium.
