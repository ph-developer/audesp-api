import 'package:audesp_api/core/database/models/user.dart';
import 'package:audesp_api/core/theme/app_theme.dart';
import 'package:audesp_api/features/auth/auth_providers.dart';
import 'package:audesp_api/features/estimativa/models/estimativa_model.dart';
import 'package:audesp_api/features/processo/domain/processo.dart';
import 'package:audesp_api/features/processo/pages/processos_page.dart';
import 'package:audesp_api/features/processo/processo_providers.dart';
import 'package:audesp_api/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../processo_fixtures.dart';

class _TestSessionNotifier extends LocalSessionNotifier {
  final User user;

  _TestSessionNotifier(this.user);

  @override
  User? build() => user;
}

const _contratacao = AppPermissions.edital | AppPermissions.licitacao;
const _contratos = AppPermissions.ata | AppPermissions.ajuste;

Future<GoRouter> _pumpPage(
  WidgetTester tester, {
  List<Processo> processos = const [],
  int permissions = _contratacao,
  Future<List<Processo>> Function()? carregar,
}) async {
  await tester.binding.setSurfaceSize(const Size(1600, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final router = GoRouter(
    initialLocation: '/processos',
    routes: [
      ShellRoute(
        builder: (context, state, child) => child,
        routes: [
          GoRoute(
            path: '/processos',
            builder: (context, state) => const ProcessosPage(),
          ),
          for (final module in [
            'edital',
            'licitacao',
            'ata',
            'ajuste',
            'estimativa',
          ])
            GoRoute(
              path: '/$module/:id',
              builder: (context, state) => Scaffold(
                body: Column(
                  children: [
                    Text('Formulário ${state.uri}'),
                    TextButton(
                      onPressed: () => context.go('/processos'),
                      child: const Text('Voltar a Processos'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localSessionProvider.overrideWith(
          () => _TestSessionNotifier(usuarioFixture(permissions: permissions)),
        ),
        processosProvider.overrideWith(
          (ref) async => carregar == null ? processos : await carregar(),
        ),
      ],
      child: MaterialApp.router(
        // Densidade compacta, a mesma que o app usa no Windows.
        theme: AppTheme.light.copyWith(visualDensity: VisualDensity.compact),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

Set<bool> _filtroPendencias(WidgetTester tester) => tester
    .widget<SegmentedButton<bool>>(find.byType(SegmentedButton<bool>))
    .selected;

Finder _chip(int editalId, String etapa) =>
    find.byKey(ValueKey('processo-$editalId-etapa-$etapa'));

void main() {
  for (final podeAcessar in [true, false]) {
    testWidgets(
      'estimativa aparece antes das etapas e respeita acesso ($podeAcessar)',
      (tester) async {
        final estimativa = EstimativaModel(
          id: 7,
          numero: 3,
          ano: 2026,
          objeto: 'Material',
        );
        final router = await _pumpPage(
          tester,
          permissions:
              _contratacao | (podeAcessar ? AppPermissions.estimativa : 0),
          processos: [
            processoFixture(estimativa: estimativa),
            processoFixture(id: 2),
          ],
        );
        final chip = find.byKey(const ValueKey('processo-1-estimativa'));
        expect(find.text('Estimativa 3/2026'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('processo-2-estimativa')),
          findsNothing,
        );
        expect(
          find.descendant(
            of: chip,
            matching: find.byIcon(Icons.calculate_outlined),
          ),
          findsOneWidget,
        );
        expect(
          tester.getTopLeft(chip).dx,
          lessThan(tester.getTopLeft(_chip(1, 'edital')).dx),
        );
        expect(
          tester.widget<ActionChip>(chip).onPressed,
          podeAcessar ? isNotNull : isNull,
        );
        await tester.tap(chip);
        await tester.pumpAndSettle();
        expect(
          router.routeInformationProvider.value.uri.path,
          podeAcessar ? '/estimativa/7' : '/processos',
        );
      },
    );
  }

  testWidgets('filtro padrão mostra só processos com pendência do usuário', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      processos: [
        processoFixture(),
        processoFixture(id: 2, status: 'draft'),
        processoFixture(
          id: 3,
          licitacoes: [licitacaoFixture(31, editalId: 3, status: 'sent')],
        ),
      ],
    );

    expect(_filtroPendencias(tester), {true});
    expect(find.text('Pendências'), findsOneWidget);
    expect(find.text('Objeto do edital 1'), findsOneWidget);
    expect(find.text('Objeto do edital 2'), findsNothing);
    expect(find.text('Objeto do edital 3'), findsNothing);
    expect(find.text('Criar licitação'), findsOneWidget);

    await tester.tap(find.text('Todos'));
    await tester.pumpAndSettle();

    expect(_filtroPendencias(tester), {false});
    for (final id in [1, 2, 3]) {
      expect(find.text('Objeto do edital $id'), findsOneWidget);
    }
  });

  testWidgets(
    'Contratos recebe só criar ata para SRP e criar ajuste para não SRP',
    (tester) async {
      await _pumpPage(
        tester,
        permissions: _contratos,
        processos: [
          processoFixture(
            srp: true,
            licitacoes: [licitacaoFixture(1, status: 'sent')],
            atas: [
              ataFixture(11, status: 'sent'),
              ataFixture(12, status: 'sent'),
            ],
          ),
          processoFixture(
            id: 2,
            srp: true,
            licitacoes: [licitacaoFixture(2, editalId: 2, status: 'sent')],
          ),
          processoFixture(
            id: 3,
            licitacoes: [licitacaoFixture(3, editalId: 3, status: 'sent')],
          ),
        ],
      );

      expect(find.text('Criar ata'), findsOneWidget);
      expect(find.text('Criar ajuste'), findsOneWidget);
      expect(find.text('Objeto do edital 1'), findsNothing);
      expect(find.text('Objeto do edital 2'), findsOneWidget);
      expect(find.text('Objeto do edital 3'), findsOneWidget);
      expect(_chip(2, 'ata'), findsOneWidget);
      expect(_chip(2, 'ajuste'), findsNothing);
      expect(_chip(3, 'ata'), findsNothing);
      expect(_chip(3, 'ajuste'), findsOneWidget);
    },
  );

  testWidgets(
    'busca combina código, modalidade, número/ano e objeto sem acentos',
    (tester) async {
      await _pumpPage(
        tester,
        processos: [
          processoFixture(
            semPncp: false,
            codigo: '1234567800019010000012026',
            objeto: 'Material de escritório',
          ),
          processoFixture(
            id: 2,
            codigo: 'LOCAL/2026',
            objeto: 'Aquisição de veículos',
          ),
        ],
      );
      expect(
        find.text('12345678000190-1-000001/2026 - Pregão Eletrônico 1/2026'),
        findsOneWidget,
      );

      for (final query in [
        'veiculos',
        'LOCAL/2026',
        'pregao eletronico%2/2026',
      ]) {
        await tester.enterText(find.byType(TextField), query);
        await tester.pumpAndSettle();

        expect(find.text('Aquisição de veículos'), findsOneWidget);
        expect(find.text('Material de escritório'), findsNothing);
      }
      for (final query in [
        '12345678000190-1-000001/2026',
        '1234567800019010000012026',
      ]) {
        await tester.enterText(find.byType(TextField), query);
        await tester.pumpAndSettle();

        expect(find.text('Material de escritório'), findsOneWidget);
        expect(find.text('Aquisição de veículos'), findsNothing);
      }

      await tester.tap(find.byTooltip('Limpar filtro'));
      await tester.pumpAndSettle();
      expect(find.text('Material de escritório'), findsOneWidget);
      expect(find.text('Aquisição de veículos'), findsOneWidget);
    },
  );

  testWidgets('código local sem PNCP é preservado mesmo com 25 dígitos', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      processos: [processoFixture(codigo: '1234567800019010000012026')],
    );

    expect(
      find.text('1234567800019010000012026 - Pregão Eletrônico 1/2026'),
      findsOneWidget,
    );
  });

  testWidgets('chip bloqueado não navega e exibe motivo no tooltip', (
    tester,
  ) async {
    final router = await _pumpPage(
      tester,
      permissions: _contratos,
      processos: [
        processoFixture(srp: true, licitacoes: [licitacaoFixture(1)]),
      ],
    );
    await tester.tap(find.text('Todos'));
    await tester.pumpAndSettle();
    final chip = _chip(1, 'ata');
    final tooltip = find.descendant(of: chip, matching: find.byType(Tooltip));
    const motivo = 'A licitação do edital ainda não foi enviada ao AUDESP.';

    expect(tester.widget<Tooltip>(tooltip).message, motivo);
    expect(
      find.descendant(of: chip, matching: find.byType(InkWell)),
      findsNothing,
    );
    expect(
      tester
          .widgetList<MouseRegion>(
            find.descendant(of: chip, matching: find.byType(MouseRegion)),
          )
          .any((region) => region.cursor == SystemMouseCursors.basic),
      isTrue,
    );
    await tester.tap(chip);
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/processos');

    await tester.longPress(chip);
    await tester.pumpAndSettle();
    expect(find.text(motivo), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/processos');
  });

  testWidgets('Contratos vê a etapa de Licitação sem a ação Nova licitação', (
    tester,
  ) async {
    final router = await _pumpPage(
      tester,
      permissions: _contratos,
      processos: [processoFixture()],
    );
    await tester.tap(find.text('Todos'));
    await tester.pumpAndSettle();

    expect(find.text('Licitação'), findsOneWidget);
    expect(find.byTooltip('Nova licitação'), findsNothing);
    expect(find.text('Criar licitação'), findsNothing);
    await tester.tap(_chip(1, 'licitacao'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/processos');
    expect(find.byType(PopupMenuItem<String>), findsNothing);
  });

  testWidgets('chip com uma ação navega com o edital selecionado', (
    tester,
  ) async {
    final router = await _pumpPage(
      tester,
      processos: [processoFixture(id: 42)],
    );

    await tester.tap(_chip(42, 'licitacao'));
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.toString(),
      '/licitacao/new?editalId=42',
    );
  });

  testWidgets(
    'chip SRP com ajustes antigos oferece só abertura e preserva navegação',
    (tester) async {
      final router = await _pumpPage(
        tester,
        permissions: _contratos,
        processos: [
          processoFixture(
            srp: true,
            licitacoes: [licitacaoFixture(1, status: 'sent')],
            atas: [
              ataFixture(11, status: 'sent'),
              ataFixture(12, status: 'sent'),
            ],
            ajustes: [
              ajusteFixture(21, ataId: 11, status: 'sent'),
              ajusteFixture(22, ataId: 11),
            ],
          ),
        ],
      );
      await tester.tap(find.text('Todos'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: _chip(1, 'ajuste'),
          matching: find.text('Rascunho · 2'),
        ),
        findsOneWidget,
      );
      await tester.tap(_chip(1, 'ajuste'));
      await tester.pumpAndSettle();

      expect(find.text('Abrir ajuste ajuste-21'), findsOneWidget);
      expect(find.text('Abrir ajuste ajuste-22'), findsOneWidget);
      expect(find.byType(PopupMenuItem<String>), findsNWidgets(2));
      expect(find.textContaining('Novo ajuste'), findsNothing);
      await tester.tap(find.text('Abrir ajuste ajuste-22'));
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.toString(),
        '/ajuste/22',
      );
    },
  );

  testWidgets('botão de pendência abre o rascunho mais recente', (
    tester,
  ) async {
    final router = await _pumpPage(
      tester,
      processos: [
        processoFixture(
          licitacoes: [
            licitacaoFixture(9, updatedAt: DateTime(2026, 10, 20)),
            licitacaoFixture(2),
          ],
        ),
      ],
    );

    await tester.tap(find.text('Enviar licitação'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/licitacao/2');
  });

  testWidgets(
    'vazio orienta a desligar o filtro e distingue a lista completa',
    (tester) async {
      await _pumpPage(tester);

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('Nenhuma pendência para você.'), findsOneWidget);
      expect(
        find.text('Selecione "Todos" para ver todos os processos.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Todos'));
      await tester.pumpAndSettle();
      expect(find.text('Nenhum processo encontrado.'), findsOneWidget);
    },
  );

  testWidgets('atualizar refaz a consulta e atualiza as pendências', (
    tester,
  ) async {
    var processos = [processoFixture()];
    var consultas = 0;
    await _pumpPage(
      tester,
      carregar: () async {
        consultas++;
        return processos;
      },
    );
    expect(consultas, 1);

    processos = [
      processoFixture(licitacoes: [licitacaoFixture(1, status: 'sent')]),
    ];
    await tester.tap(find.byTooltip('Atualizar'));
    await tester.pumpAndSettle();

    expect(consultas, 2);
    expect(find.text('Nenhuma pendência para você.'), findsOneWidget);
  });

  testWidgets('autoDispose refaz a lista ao reentrar depois de um formulário', (
    tester,
  ) async {
    var processos = [processoFixture()];
    var consultas = 0;
    await _pumpPage(
      tester,
      carregar: () async {
        consultas++;
        return processos;
      },
    );
    await tester.tap(find.text('Criar licitação'));
    await tester.pumpAndSettle();
    expect(consultas, 1);

    processos = [
      processoFixture(licitacoes: [licitacaoFixture(1, status: 'sent')]),
    ];
    await tester.tap(find.text('Voltar a Processos'));
    await tester.pumpAndSettle();

    expect(consultas, 2);
    expect(find.text('Nenhuma pendência para você.'), findsOneWidget);
  });
}
