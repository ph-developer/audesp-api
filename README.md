# AUDESP API Desktop App

Aplicativo Windows Desktop em Flutter para gerenciamento e envio de dados ao sistema AUDESP (TCE-SP).

## Pré-requisitos

Para executar o projeto, você precisará ter:

- **Flutter SDK** (`^3.11.4`)
- **MySQL 8.0:** Você pode subir um ambiente local rapidamente usando Docker (ex.: `docker compose up -d`). As credenciais padrão da aplicação local procuram pelo usuário `audesp` com senha `audesp`, no banco `audesp`.
- **Arquivo `config.ini`:** Arquivo na raiz do projeto contendo a configuração de acesso ao banco de dados (lido em tempo de execução).

## Comandos Úteis

```bash
# Rodar o aplicativo localmente no Windows
flutter run -d windows

# Rodar os testes (ex: parsers de CSV)
flutter test

# Rodar a análise estática / linting
flutter analyze

# Gerar a versão final/produção (Executável para Windows)
# O artefato ficará na pasta: build\windows\x64\runner\Release\
flutter build windows
```

## Principais Funcionalidades

- **Gerenciamento de Documentos:** Lançamento, rascunho e envio de Editais, Licitações, Atas e Ajustes ao sistema do TCE-SP.
- **Consultas de Protocolo:** Verificação em tempo real do status dos documentos submetidos à API do AUDESP.
- **Relatórios:** Geração de relatórios e trilhas de auditoria (logs) exportáveis em formato PDF.
- **Integração com IA (Gemini):** Extração inteligente de dados a partir de documentos utilizando o Google Gemini.
- **Múltiplos Formatos:** Importadores embutidos com suporte para leitura de tabelas CSV (UTF-8, Latin-1) e planilhas Excel.

## Arquitetura e Bibliotecas

- **Gerenciamento de Estado:** Construído com [Riverpod](https://riverpod.dev/).
- **Roteamento:** Baseado em [GoRouter](https://pub.dev/packages/go_router) utilizando rotas aninhadas (`ShellRoute`) para o menu lateral.
- **Banco de Dados Local:** O banco usa o driver `mysql_client`. O esquema de tabelas (versão) e o usuário administrador principal são semeados (auto-criados) na primeira execução do sistema.
- **Armazenamento Seguro:** As senhas da sessão são criptografadas via DPAPI nativo do Windows (através do pacote `flutter_secure_storage`).
- **Comunicação de Rede:** O consumo da API do piloto/oficial do AUDESP é feito com [Dio](https://pub.dev/packages/dio), que utiliza *interceptors* para adicionar o *Bearer Token* automaticamente de maneira segura.
