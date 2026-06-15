## Edital

| Tag | Descrição | Resposta | Obrigatoriedade | PNCP | Observação/ Validação | Retificação | grupo |
|-----|-----------|----------|-----------------|------|-----------------------|-------------|-------|
| municipio | Conforme lista de Municípios e Entidades AUDESP |  | Obrigatório | N |  | Não permitir retificação deste campo | Descritor |
| entidade | Conforme lista de Municípios e Entidades AUDESP |  | Obrigatório | N |  | Não permitir retificação deste campo | Descritor |
| codigoEdital | Identificador da compra. Deve ser único por entidade. Se a entidade efetuou a publicação via Portal Nacional de Compras Públicas deve ser utilizado o número de controle da contratação (id contratação pncp). |  | Obrigatório | S | 25 caracteres Se algum "veiculoPublicacao" = 5 (PNCP) valida se o codigoEdital existe no PNCP No PNCP cada contratação receberá um número de controle composto por: -CNPJ do Órgão/Entidade da contratação (14 dígitos) -Dígito "1" marcador que indica tratar-se de uma contratação (1 dígito) -Número sequencial da contratação no PNCP (6 dígitos) -Ano da contratação (4 dígitos) | Não permitir retificação deste campo | Descritor |
| retificacao | Informa se é o caso de retificação de informação já prestada na Fase IV - AUDESP. | true, false | Obrigatório | N | Verificar se informação já foi prestada (municipio, entidade e codigoEdital) | Não permitir retificação se Ajuste foi selecionado. | Descritor |
| houvePublicacao | Informa se houve publicação do instrumento convocatório em veículos de comunicação | true, false | Obrigatório | N |  | Permitir |  |
| dataPublicacao | Data de publicação do instrumento convocatório |  | Obrigatório ao menos uma se "houvePublicacao" = Sim | N |  | Permitir | Lista de Publicações |
| veiculoPublicacao | Veículo de comunicação em que o instrumento convocatório foi publicado | Domínio AUDESP: Veículo Comunicação | Obrigatório se "dataPublicacao" preenchida | N |  | Permitir | Lista de Publicações |
| idContratacaoPNCP | Número de Controle PNCP da Contratação |  | Obrigatório se "veiculoPublicacao" = 5 |  | 25 caracteres Se algum "veiculoPublicacao" = 5 (PNCP) valida se o codigoEdital existe no PNCP No PNCP cada contratação receberá um número de controle composto por: -CNPJ do Órgão/Entidade da contratação (14 dígitos) -Dígito "1" marcador que indica tratar-se de uma contratação (1 dígito) -Número sequencial da contratação no PNCP (6 dígitos) -Ano da contratação (4 dígitos) |  | Lista de Publicações |
| veiculoPublicacaoNome | Descrição do veículo de comunicação em que o instrumento convocatório foi publicado |  | Obrigatório se "veiculoPublicacao" = 10 (Outros) | N |  | Permitir | Lista de Publicações |
| codigoUnidadeCompradora | Código da unidade compradora no PNCP. |  | Facultativo | S |  | Permitir |  |
| tipoInstrumentoConvocatorioId | Código da tabela de domínio Tipo de instrumento convocatório. | Domínio PNCP: Tipo Instrumento convocatório | Obrigatório | S | Validar o campo com a Modalidade de Contratação, conforme tabela de Domínio "Instrumento Convocatório" | Permitir |  |
| modalidadeId | Modalidade de contratação | Domínio PNCP com alterações AUDESP: Modalidade de Contratação | Obrigatório | S |  | Não permitir retificar se houver Licitação cadastrada, pois o campo "tipoPessoaId" da Licitação é validado com as informações cadastradas no Edital |  |
| modoDisputaId | Código da tabela de domínio Modo de disputa. | Domínio PNCP: Modo de disputa | Obrigatório | S |  | Permitir |  |
| numeroCompra | Número da contratação no sistema de origem sem o ano. Esse número é gerado pelo usuário no seu sistema de origem (ex. Pregão 14)  |  | Obrigatório | S |  | Permitir |  |
| anoCompra | Ano da contratação. Esse é o ano relacionado ao número da contratação. |  | Obrigatório | S |  | Permitir |  |
| numeroProcesso | Número do processo de contratação no sistema de origem |  | Obrigatório | S |  | Permitir |  |
| objetoCompra | Objeto da contratação  |  | Obrigatório | S |  | Permitir |  |
| informacaoComplementar | Informações complementares; Se existir;  |  | Facultativo | S |  |  |  |
| srp | Identifica se a compra trata-se de um SRP (Sistema de registro de preços). | true, false | Obrigatório | S |  | Não permitir retificar se houver Licitação cadastrada, pois o campo "codigoEdital"  e "codigoAta" do Ajuste, "codigoEdital" da Ata é validado com as informações cadastradas no Edital. |  |
| dataAberturaProposta | Informar a data e hora de início do recebimento das propostas (pelo horário de Brasília)  |  | Obrigatório para Tipo de Instrumento Convocatório 1  (edital) ou 2 (aviso de contratação direta: dispensa com disputa). | S |  | Permitir |  |
| dataEncerramentoProposta | Informar a data e hora de encerramento do recebimento das propostas (pelo horário de Brasília) |  | Obrigatório para Tipo de Instrumento Convocatório 1 (edital) ou 2 (aviso de contratação direta: dispensa com disputa). | S |  | Permitir |  |
| amparoLegalId | Código da tabela de domínio Amparo Legal. | Domínio PNCP com alterações AUDESP: Amparo Legal | Obrigatório | S |  | Permitir |  |
| linkSistemaOrigem | URL para página/portal do sistema de origem da contratação para recebimento de proposta/lance.  |  | Facultativo | S |  | Permitir |  |
| justificativaPresencial | Justificativa pela escolha da modalidade presencial.  |  | Facultativo | S |  | Permitir |  |
| itensCompra | Lista de itens da contratação |  | Obrigatório | S |  | Permitir |  |
| numeroItem | Número do item na contratação (único e sequencial crescente) |  | Obrigatório ao menos um | S |  | Não permitir excluir item se houver Licitação cadastrada, pois o campo "numeroItem" da Licitação é validado com as informações cadastradas no Edital | Lista de Itens |
| materialOuServico | Identifica se o item refere-se a material ou a serviço | M - Material; S - Serviço; Contratações na modalidade leilão informar M. | Obrigatório | S |  | Permitir | Lista de Itens |
| tipoBeneficioId | Identifica se há benefício relacionado à Lei 123/2006 | Domínio PNCP: Tipo de Benefício | Obrigatório | S |  | Não permitir retificar se houver Licitação cadastrada, pois o campo "resultadoHabilitacao" da Licitação é validado com as informações cadastradas no Edital | Lista de Itens |
| incentivoProdutivoBasico | Incentivo fiscal PPB (Processo Produtivo Básico) | true - Possui o incentivo; false - Não possui o incentivo; | Obrigatório | S |  | Permitir | Lista de Itens |
| descricao | Descrição para o produto ou serviço |  | Obrigatório | S |  | Permitir | Lista de Itens |
| quantidade | Quantidade do item da contratação. Precisão de 4 dígitos decimais |  | Obrigatório | S |  | Permitir | Lista de Itens |
| unidadeMedida | Unidade de medida do item da contratação |  | Obrigatório | S |  | Permitir | Lista de Itens |
| orcamentoSigiloso | Identifica se o orçamento do item é sigiloso |  true - Sigiloso; false - Não sigiloso | Obrigatório | S |  | Permitir | Lista de Itens |
| valorUnitarioEstimado | Valor unitário estimado para o item da contratação. Precisão de 4 dígitos decimais |  | Obrigatório | S |  | Permitir | Lista de Itens |
| valorTotal | Valor total estimado para a contratação |  | Obrigatório | S |  | Permitir | Lista de Itens |
| criterioJulgamentoId | Critério de julgamento | Domínio PNCP com alterações AUDESP: Critério de julgamento | Obrigatório | S |  | Permitir | Lista de Itens |
| itemCategoriaId | Categoria do item. Domínios 1 ou 2 aplicados à modalidade leilão. Outras modalidades de contratação utilizar o domínio 3. | 1 – Bens Imóveis; 2 – Bens Móveis; 3 - Não se aplica | Obrigatório | S |  | Permitir | Lista de Itens |
| patrimonio | Código de Patrimonio do Item de bens móveis quando existir |  | Facultativo | S |  | Permitir | Lista de Itens |
| codigoRegistroImobiliario | Código de Registro Imobiliário. |  | Facultativo | S |  | Permitir | Lista de Itens |
|  |  |  |  |  |  |  |  |

## Licitação

| Tag | Descrição | Resposta | Obrigatoriedade | PNCP | Observação | Retificação | grupo | grupo acima |
|-----|-----------|----------|-----------------|------|------------|-------------|-------|-------------|
| municipio | Conforme lista de Municípios e Entidades AUDESP |  |  | N |  | Não permitir retificação deste campo | descritor |  |
| entidade | Conforme lista de Municípios e Entidades AUDESP |  |  | N |  | Não permitir retificação deste campo | descritor |  |
| codigoEdital | Identificador da compra. Deve ser único por entidade. Se a entidade efetuou a publicação via Portal Nacional de Compras Públicas deve ser utilizado o número de controle da contratação (id contratação pncp). |  | Obrigatório. Validar se para a entidade existe o código informado no documento EDITAL | S | 25 caracteres | Não permitir retificação deste campo | descritor |  |
| retificacao |  Informa se é o caso de retificação de informação já prestada na Fase IV - AUDESP. | true, false | Obrigatório | N | Verificar se informação já foi prestada (Licitação com codigoEdital) | Não permitir retificação se Ajuste foi selecionado. | descritor |  |
| recursoBID | Informa se há recursos do Banco Interamericano de Desenvolvimento - BID - envolvidos | 1 - Sim; 2 - Não; 3 - Não se Aplica;  | Obrigatório | N |  | Permitir |  |  |
| aberturaPreQualificacaoBID | Informa se houve objeção do BID ao aviso de abertura da pré-qualificação? | 1 - Sim; 2 - Não; 3 - Não se Aplica;  | Facultativo | N |  | Permitir |  |  |
| editalPreQualificacaoBID | Informa se houve objeção do BID ao Edital da fase de Pré-qualificação | 1 - Sim; 2 - Não; 3 - Não se Aplica;  | Facultativo | N |  | Permitir |  |  |
| julgamentoPreQualificacaoBID | Informa se houve objeção do BID ao julgamento da fase de Pré-qualificação | 1 - Sim; 2 - Não; 3 - Não se Aplica;  | Facultativo | N |  | Permitir |  |  |
| edital2FaseBID | Informa se houve objeção do BID ao Edital da 2a. Fase | 1 - Sim; 2 - Não; 3 - Não se Aplica;  | Facultativo | N |  | Permitir |  |  |
| julgamentoPropostasBID | Informa se houve objeção do BID ao julgamento das propostas técnicas comerciais | 1 - Sim; 2 - Não; 3 - Não se Aplica;  | Facultativo | N |  | Permitir |  |  |
| julgamentoNegociacaoBID | Houve objeção do BID ao julgamento da negociação final? | 1 - Sim; 2 - Não; 3 - Não se Aplica;  | Facultativo | N |  | Permitir |  |  |
| tipoNatureza | Informa o tipo de concessão, permissão, credenciamento ou SRP | Domínio AUDESP: Tipo de Natureza | Obrigatório | N |  | Permitir |  |  |
| viabilidadeContratacao | Informa se consta do procedimento parecer técnico-jurídico atestando a viabilidade da contratação | 1 - Sim; 2 - Não; 3 - Não se Aplica;  | Facultativo | N |  | Permitir |  |  |
| interposicaoRecurso | Informa se houve interposição de recurso administrativo no processo de compra | 1 - Sim; 2 - Não; 3 - Não se Aplica;  | Obrigatório | N |  | Permitir |  |  |
| audienciaPublica | Informa se houve audiência pública relativa ao processo licitatório | 1 - Sim; 2 - Não; 3 - Não se Aplica;  | Facultativo | N |  | Permitir |  |  |
| exigenciaGarantiaLicitantes | Informa se houve exigência de garantia para participação da licitação | 1 - Sim; 2 - Não; 3 - Não se Aplica;  | Obrigatório | N |  | Permitir |  |  |
| percentualValor | Percentual do valor referente à garantia exigida |  | Facultativo | N |  | Permitir |  |  |
| percentualValor | Informa se há exigência de amostras? | 1- Sim,para todos os licitantes; 2 - Sim, somente do vencedor do certame; 3 - Não; | Facultativo | N |  | Permitir |  |  |
| quitacaoTributosFederais | Informa se, no edital, há exigência de prévia quitação de tributos federais pelos licitantes |  true, false | Facultativo | N |  | Permitir |  |  |
| quitacaoTributosEstaduais | Informa se, no edital, há exigência de prévia quitação de tributos estaduais pelos licitantes |  true, false | Facultativo | N |  | Permitir |  |  |
| quitacaoTributosMunicipais | Informa se, no edital, há exigência de prévia quitação de tributos municipais pelos licitantes |  true, false | Facultativo | N |  | Permitir |  |  |
| exigenciaVisitaTecnica | No caso de obras e serviços de engenharia, há exigência de visita ou vistoria técnica no edital? | 1- Sim; 2- Não; 3- O processo não se refere à obra nem a serviço de engenharia;  | Facultativo | N |  | Permitir |  |  |
| exigenciaCurriculo | Há exigência de apresentação de currículo dos profissionais indicados para a visita técnica? | 1 - Sim; 2 - Não; | Facultativo, porém obrigatório se "exigenciaVisitaTecnica" = Sim | N |  | Permitir |  |  |
| exigenciaVistoCREA | Há exigência de visto do CREA/SP para empresas sediadas em outros estados? | 1 - Sim; 2 - Não; | Facultativo, porém obrigatório se "exigenciaVisitaTecnica" = Sim | N |  | Permitir |  |  |
| declaracaoRecursosContratacao | Informa se houve declaração da existência de recursos orçamentários para a contratação | 1 - Sim; 2 - Não; | Facultativo | N |  | Permitir |  |  |
| fonteRecursosContratacao | Informa a(s) Fonte(s) de Recurso(s) que constam na  declaração da existência de recursos orçamentários para a contratação | Domínio AUDESP: Fonte de Recursos | Obrigatório ao menos um. | N |  | Permitir | lista de fontes de recurso |  |
| contratacaoConduzida | Informa se a contratação foi conduzida por um agente de contratação ou  comissão |  true, false | Obrigatório | N |  | Permitir |  |  |
| cpfCondutor | CPF |  | Obrigatório ao menos um CPF se "contratacaoConduzida" =  true.  | N | Deve ser uma lista, apenas CPFs com validação na Receita | Permitir | lista de condutores |  |
| exigenciaIndicesEconomicos | Há exigência de índices econômicos mínimos? | 1 - Sim; 2 - Não; 3 - Não se Aplica;  | Facultativo | N |  | Permitir |  |  |
| tipoIndice | Índice econômico | Domínio AUDESP: Índice Econômico |  Facultativo, porém obrigatório se campo "Há exigência de índices econômicos mínimos?" = Sim | N |  | Permitir | Lista de Índices Econômicos |  |
| nomeIndice | Descreva o índice econômico |  | Obrigatório se campo "Índice econômico:" = Outro | N |  | Permitir | Lista de Índices Econômicos |  |
| valorIndice | Valor exigido do índice |  | Facultativo, porém obrigatório se campo "Há exigência de índices econômicos mínimos?" = Sim | N | Númerico, duas casas decimais Mínimo 0,00 Máximo 999.999.999.999,00 | Permitir | Lista de Índices Econômicos |  |
| numeroItem | Número do Item |  | Obrigatório ao menos um. Validar se constam todos os itens enviados no Edital, não permitir numeroItem duplicado | S |  | Não permitir retificação deste campo se houver Ata ou Ajuste cadastrado, pois o campo "numeroItem" da Ata ou do  Ajuste é validado com as informações cadastradas na Licitação. |  | Lista de Itens |
| tipoOrcamento | Informa se foi realizado Orçamento e seu tipo | Domínio AUDESP: Orçamento ou Proposta | Obrigatório | N |  | Permitir |  | Lista de Itens |
| valor | Valor médio dos orçamentos |  | Obrigatório se campo "tipoOrcamento" <> 0 (Não) | N | Valor monetário (1,2) ou percentual (3), de acordo com opção do campo "Foi realizado Orçamento". Aceitar até 4 casas decimais | Permitir |  | Lista de Itens |
| dataOrcamento | Data em que foi realizado o primeiro orçamento ou a primeira pesquisa de preço |  | Obrigatório se "valor" for preenchido | N |  | Permitir |  | Lista de Itens |
| situacaoCompraItemId | Informa a última situação do Item na data em que a informação está sendo prestada | Domínio PNCP: Situação do Item da Contratação | Obrigatório.  | S |  | Permitir |  | Lista de Itens |
| dataSituacaoItem | Data da Situação do Item |  | Obrigatório | N | Campo Data. Limite mínimo (Hoje - 30 anos). Limite máximo: Data da prestação da informação | Permitir |  | Lista de Itens |
| tipoValor | O valor da proposta refere-se a um valor monetário ou a um valor percentual? | P - Percentual; M - Monetário | Obrigatório. | N |  | Permitir |  | Lista de Itens |
| tipoProposta | Informa o tipo da proposta do item | Domínio AUDESP: Orçamento ou Proposta | Obrigatório | N | Não pode ser informado 0  "Não" | Permitir |  | Lista de Itens |
| tipoPessoaId | Tipo de pessoa: | PF - Pessoa Física; PJ - Pessoa Jurídica; PE - Pessoa Estrangeira | Verifica nos campos do documento EDITAL  e Licitação: Facultativo: Se (Modalidade de contratação = Dispensa, Inexigibilidade ou Credenciamento) OU (Situação do Item <> 2 (Homologado/Adjudicado). Obrigatório ao menos um licitante nas outras situações. | N | Não pode ser enviado o mesmo licitante mais de uma vez em cada item (identificação de cada licitante = tipoPessoaId, niPessoa) | Permitir | Lista de licitantes referentes a um Item | Lista de Itens |
| niPessoa | Número do documento: |  | Obrigatório se "tipoPessoaId for preenchido.  | N | Validação conforme informado no campo "tipoPessoaId". Validação com dados da Receita: CPF se "PF",  CNPJ  se "PJ". Não há validação para "PE". | Permitir | Lista de licitantes referentes a um Item | Lista de Itens |
| nomeRazaoSocial | Nome ou Razão Social do licitante/fornecedor: |  | Obrigatório se "Tipo de pessoa" = "PE" | N |  | Permitir | Lista de licitantes referentes a um Item | Lista de Itens |
| declaracaoMEouEPP | Informa se o licitante apresentou declaração de Microempresa ou Empresa de Pequeno Porte | Domínio AUDESP: Declaração ME EPP | Obrigatório se "Tipo de pessoa" for preenchido. | N |  | Permitir | Lista de licitantes referentes a um Item | Lista de Itens |
| Valor | Valor da Proposta ($) |  | Obrigatório se "Tipo de pessoa" for preenchido E (resultado da habilitação = Classificado Vencedor (1) ou Classificado (2)). Valor monetário ou percentual, de acordo com opção do campo "O valor da proposta refere-se a um valor monetário ou a um valor percentual?". Aceitar até 4 casas decimais | N |  | Permitir | Lista de licitantes referentes a um Item | Lista de Itens |
| resultadoHabilitacao | Resultado da habilitação ou do item | Domínio AUDESP: Resultado Habilitação | Obrigatório se tipoPessoaId for preenchido.  | N | O sistema deve aceitar apenas um vencedor por Lote (Resultado da habilitação = 1) Exceto se o campo Edital "tipoBeneficioId" = 3 (cota reservada ME/EPP), neste caso em que pode haver 2 vencedores (Resultado da habilitação = 1) | Permitir | Lista de licitantes referentes a um Item | Lista de Itens |
|  |  |  |  |  |  |  |  |  |

## Ata

| Tag | Descrição | Resposta | Obrigatoriedade | PNCP | Observação | Retificação |
|-----|-----------|----------|-----------------|------|------------|-------------|
| municipio | Conforme lista de Municípios e Entidades AUDESP |  |  | N |  | Não permitir retificação deste campo |
| entidade | Conforme lista de Municípios e Entidades AUDESP |  |  | N |  | Não permitir retificação deste campo |
| retificacao | Informa se é o caso de retificação de informação já prestada na Fase IV - AUDESP. | true, false | Obrigatório | N | Verificar se informação já foi prestada (codigoAta) | Não permitir retificação se algum Ajuste foi selecionado. |
| anoCompra | Ano da contratação |  | Obrigatório | S |  | Não permitir retificação deste campo |
| codigoEdital  | Identificador da compra. Deve ser único por entidade. Se a entidade efetuou a publicação via Portal Nacional de Compras Públicas deve ser utilizado o número de controle da contratação (id contratação pncp). |  | Obrigatório | S | Validar se "srp" (Edital) = True. 25 caracteres | Não permitir retificação deste campo |
| numeroItem | Número do Item |  | Obrigatório | N | Lista. Não permitir duplicidade de item. Validar se existe o numeroItem informado no documento LICITAÇÃO  | Permitir |
| codigoAta | Identificador da ata de registro de preços. Se a entidade efetuou a publicação via Portal Nacional de Compras Públicas deve ser utilizado o  número de controle da ata gerado pelo PNCP. |  | Obrigatório | S | Não permitir duplicidade de ata: município, entidade e codigoAta Se no Edital (codigoEdital) "veiculoPublicacao" = 5 (PNCP na Contratação) valida se o codigoAta existe no PNCP 31 caracteres No PNCP cada ata receberá um número de controle composto por: -Número de Controle PNCP da Contratação (25 dígitos) -Número sequencial da ata no PNCP (6 dígitos) | Não permitir retificação deste campo |
| numeroAtaRegistroPreco | Número da ata no sistema de origem |  | Obrigatório | S |  | Permitir |
| anoAta | Ano da ata |  | Obrigatório | S |  | Permitir |
| dataAssinatura | Informar a data de assinatura da ata |  | Obrigatório | S |  | Permitir |
| dataVigenciaInicio | Informar a data de início de vigência da ata |  | Obrigatório | S |  | Permitir |
| dataVigenciaFim  | Informar a data do fim de vigência da ata |  | Obrigatório | S |  | Permitir |
|  |  |  |  |  |  |  |

## Ajuste

| Tag | Descrição | Resposta | Obrigatoriedade | PNCP | Observação | Retificação | grupo |
|-----|-----------|----------|-----------------|------|------------|-------------|-------|
| municipio | Conforme lista de Municípios e Entidades AUDESP |  |  | N |  | Não permitir retificação deste campo. |  |
| entidade | Conforme lista de Municípios e Entidades AUDESP |  |  | N |  | Não permitir retificação deste campo. |  |
| adesaoParticipação | Informa se é o caso de adesão ou participação em licitação gerenciada por outra entidade | true, false | Obrigatório | N |  | Não permitir retificação deste campo. |  |
| gerenciadoraJurisdicionada | Entidade gerenciadora da licitação é jurisdicionada ao TCE-SP? | true, false | Obrigatório se "adesaoParticipação" = "Sim" | N |  | Não permitir retificação deste campo se Ajuste foi selecionado. |  |
| retificacao | Informa se é o caso de retificação de informação já prestada na Fase IV - AUDESP. | true, false | Obrigatório | N | Verificar se informação já foi prestada (codigoContrato) | Não permitir retificação se Ajuste foi selecionado. |  |
| municipioGerenciador | Conforme lista de Municípios e Entidades AUDESP |  | Obrigatório se "gerenciadoraJurisdicionada" =  True.  | N |  | Permitir | Identificação Entidade Gerenciadora da Licitação |
| entidadeGerenciadora | Conforme lista de Municípios e Entidades AUDESP |  | Obrigatório se "gerenciadoraJurisdicionada" =  True.  | N |  | Permitir | Identificação Entidade Gerenciadora da Licitação |
| codigoEdital | Identificador da compra. Deve ser único por entidade. Se a entidade efetuou a publicação via Portal Nacional de Compras Públicas deve ser utilizado o número de controle da contratação (id contratação pncp). |  | Obrigatório | S | Validar se a Licitação foi cadastrada: -Se "adesaoParticipação" = false: município, entidade e codigoEdital -Se "adesaoParticipação" =  true E "gerenciadoraJurisdicionada" =  true: municipioGerenciador, entidadeGerenciadora e codigoEdital -Se "adesaoParticipação" =  true E "gerenciadoraJurisdicionada" =  false: Verifica se codigoEdital existe no PNCP | Permitir |  |
| codigoAta | Identificador da ata de registro de preços. Se a entidade efetuou a publicação via Portal Nacional de Compras Públicas deve ser utilizado o  número de controle da ata gerado pelo PNCP ((id ata pncp). |  | Obrigatório: [Se "adesaoParticipação" =  false e "srp" (Edital: município, entidade, codigoEdital) = True] OU [Se gerenciadoraJurisdicionada = 1 true e "srp" (Edital: municipioGerenciador, entidadeGerenciadora, codigoEdital) = True] OU [Se gerenciadoraJurisdicionada = 2 false e consulta se o codigoEdital no PNCP retorna uma Ata] | S | Validar se a Ata foi cadastrada: -Se "adesaoParticipação" =  false: município, entidade, codigoEdital  e codigoAta -Se "adesaoParticipação" =  true E "gerenciadoraJurisdicionada" =  true: municipioGerenciador, entidadeGerenciadora, codigoEdital e codigoAta -Se "adesaoParticipação" =  true E "gerenciadoraJurisdicionada" =  false: Verifica se codigoAta existe no PNCP | Permitir |  |
| codigoContrato | Identificador do ajuste. Se a entidade efetuou a publicação via Portal Nacional de Compras Públicas deve ser utilizado o número de controle da contrato (id contrato pncp). |  | Obrigatório | S | Se "veiculoPublicacao" = 5 (PNCP no Edital) valida se o codigoContrato existe no PNCP 25 caracteres No PNCP cada contrato receberá um número de controle composto por: -CNPJ do Órgão/Entidade do contrato (14 dígitos) -Dígito "2" marcador que indica tratar-se de um contrato (1 dígito) -Número sequencial da contratação no PNCP (6 dígitos) -Ano do contrato (4 dígitos) | Não permitir retificação deste campo. |  |
| fonteRecursosContratacao | Informa a(s) Fonte(s) de Recurso(s) orçamentários para a contratação | Domínio AUDESP: Fonte de Recursos | Obrigatório ao menos um. | N |  | Permitir | Lista de Fonte de Recurso |
| itens | Número do Item, conforme enviado na Licitação |  | Obrigatório ao menos um. | N | Lista. Não permitir duplicidade de item. Validar se existe o numeroItem informado: -se "adesaoParticipação" =  False, no documento LICITAÇÃO (municipio, entidade e codigoEdital) -se "gerenciadoraJurisdicionada" =  True, no documento LICITAÇÃO (municipioGerenciador, entidadeGerenciadora e codigoEdital) -se "gerenciadoraJurisdicionada" =  False, verificar o item no PNCP (codigoEdital) | Permitir | Lista de itens |
| tipoContratoId |  | Domínio PNCP: Tipo de Contrato | Obrigatório | S |  | Não permitir retificar para 7 (empenho) se houver Empenho de Contrato cadastrado |  |
| numeroContratoEmpenho | Número do contrato ou empenho com força de contrato no sistema de origem |  | Obrigatório | S |  | Permitir |  |
| anoContrato | Ano do contrato ou do Empenho |  | Obrigatório | S |  | Permitir |  |
| processo | Número do processo no sistema da origem |  | Obrigatório | S |  | Permitir |  |
| categoriaProcessoId |  | Domínio PNCP: Categoria do Processo | Obrigatório | S |  | Permitir |  |
| receita | Informa se o processo gera receita ou despesa para a entidade. | Receita ou despesa: True - Receita; False - Despesa; | Obrigatório | S |  | Permitir |  |
| despesas | Classificação Econômica da Despesa até o nível de elemento. A tabela com a codificação vigente por exercício pode ser consultada na página de documentação AUDESP (Anexo II - Tabelas de Escrituração Contábil - Auxiliares 2024.xlsx): https://www.tce.sp.gov.br/audesp/documentacao?tipo=65&termo= |  | Obrigatório se: -"tipoContratoId" = 7 (Empenho) OU -"receita" = False (Despesa) E "CodigoTipoOrgao" = 1, 2, 3, 4, 5, 6, 9, 10, 13, 19, 20, 25, 42, 43 (Prefeitura Municipal, Secretaria, Unidade de Secretaria, Tribunal, Assembleia, Ministério, Autarquia Estadual, Autarquia Municipal, Câmara, Entidade de Previdência Estadual, Entidade de Previdência Municipal, Fundo de Previdência Municipal, Fundo Especial de Despesa - FED, Unidade Administrativa - Autarquia) | N | Se for "tipoContrato" = 7 (Empenho) deve informar apenas um, se outra opção pode ser informado mais de um | Permitir | Lista de classificação de despesa |
| codigoUnidade | Codigo solicitado pelo Portal Nacional de Compras Públicas às entidades que efetuaram a publicação via PNCP |  | Facultativo | S |  | Permitir |  |
| niFornecedor | Número de identificação do fornecedor/arrematante; CNPJ, CPF ou identificador de empresa estrangeira; |  | Obrigatório | S | Validação conforme informado no campo "tipoPessoaFornecedor". Validação com dados da Receita: CPF se "PF",  CNPJ  se "PJ". Não há validação para "PE". | Permitir |  |
| tipoPessoaFornecedor |  | PJ - Pessoa jurídica; PF - Pessoa física; PE - Pessoa estrangeira; | Obrigatório | S |  | Permitir |  |
| nomeRazaoSocialFornecedor | Nome ou razão social do fornecedor/arrematante |  | Obrigatório | S |  | Permitir |  |
| niFornecedorSubContratado | Número de identificação do fornecedor subcontratado; CNPJ, CPF ou identificador de empresa estrangeira; Somente em caso de subcontratação; Não se aplica a leilão |  | Facultativo | S | Validação conforme informado no campo "tipoPessoaFornecedorSubcontratado". Validação com dados da Receita: CPF se "PF",  CNPJ  se "PJ". Não há validação para "PE". | Permitir |  |
| tipoPessoaFornecedorSubContratado |  | PJ - Pessoa jurídica; PF - Pessoa física; PE - Pessoa estrangeira; Somente em caso de subcontratação; Não se aplica a leilão | Facultativo | S |  | Permitir |  |
| nomeRazaoSocialFornecedorSubContratado | Nome ou razão social do fornecedor subcontratado; Somente em caso de subcontratação; Não se aplica a leilão |  | Facultativo | S | Texto (100) | Permitir |  |
| objetoContrato | Descrição do objeto do contrato |  | Obrigatório | S | Texto (5120) | Permitir |  |
| informacaoComplementar | Informações complementares; Se existir; |  | Facultativo | S |  | Permitir |  |
| valorInicial | Valor inicial do contrato ou nota de empenho. Precisão de 4 dígitos decimais |  | Obrigatório | S |  | Permitir |  |
| numeroParcelas | Número de parcelas |  | Facultativo | S |  | Permitir |  |
| valorParcela | Valor da parcela. Precisão de 4 dígitos decimais |  | Facultativo | S |  | Permitir |  |
| valorGlobal | Valor global do contrato; Precisão de 4 dígitos decimais |  | Facultativo | S |  | Permitir |  |
| valorAcumulado | Valor acumulado do contrato; Precisão de 4 dígitos decimais; Ex: 100.0000; |  | Facultativo | S |  | Permitir |  |
| dataAssinatura | Data de assinatura do contrato ou emissão da nota de empenho |  | Obrigatório | S |  | Permitir |  |
| dataVigenciaInicio | Data de início de vigência do contrato |  | Obrigatório se: ("tipoContratoId" = 1, 2, 3, 4, 5, 8 ou 12) E ("vigenciaMeses" não preenchido) | S |  | Permitir |  |
| datavigenciaFim | Data do término da vigência do contrato |  | Obrigatório se dataVigenciaInicio for informada | S |  | Permitir |  |
| vigenciaMeses | Quando não houver definição da data inicial da vigência, a validade do contrato pode ser informada em quantidade de meses. No documento de atualização do contrato será possível informar a data inicial da vigência quando ocorrer |  | Obrigatório se  ("tipoContratoId" = 1, 2, 3, 4, 5, 8 ou 12) e dataVigenciaInicio não preenchido | N |  | Permitir |  |
| tipoObjetoContrato | Tipo de objeto do contrato | Domínio AUDESP: Tipo objeto do contrato | Obrigatório | N | Validar com o campo "categoriaProcessoId", conforme aba de domínio "Objeto do contrato" | Permitir |  |
|  |  |  |  |  |  |  |  |

## Empenho de Contrato

| Tag | Descrição | Resposta | Obrigatoriedade | PNCP | Observação | Retificação |
|-----|-----------|----------|-----------------|------|------------|-------------|
| municipio | Conforme lista de Municípios e Entidades AUDESP |  | Obrigatório | N |  | Não permitir retificação deste campo. |
| entidade | Conforme lista de Municípios e Entidades AUDESP |  | Obrigatório | N |  | Não permitir retificação deste campo. |
| codigoContrato | Identificador do ajuste. Se a entidade efetuou a publicação via Portal Nacional de Compras Públicas deve ser utilizado o número de controle da contrato (id contrato pncp). |  | Obrigatório | S | Validar se Ajuste tem tipoContratoId <> 7 (Empenho) 25 caracteres No PNCP cada contrato receberá um número de controle composto por: -CNPJ do Órgão/Entidade do contrato (14 dígitos) -Dígito "2" marcador que indica tratar-se de um contrato (1 dígito) -Número sequencial do contrato no PNCP (6 dígitos) -Ano do contrato (4 dígitos) | Não permitir retificação deste campo. |
| retificacao | Informa se é o caso de retificação de informação já prestada na Fase IV - AUDESP. | true, false | Obrigatório | N | Verificar se informação já foi prestada (codigoEmpenho) | Não permitir retificação deste campo. |
| numeroEmpenho | Número do empenho. |  | Obrigatório | N | Verificar se informação já foi prestada (municipio, entidade, numeroEmpenho, anoEmpenho) | Permitir |
| anoEmpenho | Ano do empenho. |  | Obrigatório | N |  | Permitir |
| dataEmissaoEmpenho | Data de emissão do empenho. |  | Obrigatório | N | Data deve ser anterior à data atual. | Permitir |
|  |  |  |  |  |  |  |

## Termo de Contrato

| Tag | Descrição | Resposta | Obrigatoriedade | PNCP | Observação | Retificação |
|-----|-----------|----------|-----------------|------|------------|-------------|
| municipio | Conforme lista de Municípios e Entidades AUDESP |  | Obrigatório | N |  | Não permitir retificação deste campo. |
| entidade | Conforme lista de Municípios e Entidades AUDESP |  | Obrigatório | N |  | Não permitir retificação deste campo. |
| codigoContrato | Identificador do ajuste. Se a entidade efetuou a publicação via Portal Nacional de Compras Públicas deve ser utilizado o número de controle da contrato (id contrato pncp). |  | Obrigatório | S | Validar se Ajuste tem tipoContratoId <> 7 (Empenho) 25 caracteres No PNCP cada contrato receberá um número de controle composto por: -CNPJ do Órgão/Entidade do contrato (14 dígitos) -Dígito "2" marcador que indica tratar-se de um contrato (1 dígito) -Número sequencial do contrato no PNCP (6 dígitos) -Ano do contrato (4 dígitos) | Não permitir retificação deste campo. |
| codigoTermoContrato | Identificador do Termo de Contrato. Se a entidade efetuou a publicação via Portal Nacional de Compras Públicas deve ser utilizado o número de controle do Termo de Contrato. |  | Obrigatório | N | 30 caracteres Se "veiculoPublicacao" = 5 (PNCP no Edital) valida se o Termo de Contrato existe no PNCP No PNCP cada termo de contrato receberá um número de controle composto por: -CNPJ do Órgão/Entidade do contrato (14 dígitos) -Número sequencial do contrato no PNCP (6 dígitos) -Número sequencial do termo de contrato no PNCP (6 dígitos) -Ano do contrato (4 dígitos) | Não permitir retificação deste campo. |
| tipoTermoContratoId | Código da tabela de domínio Tipo de termo de contrato  | Domínio PNCP: Tipo Termo Contrato | Obrigatório | S | Permite apenas Termo Aditivo (2) | Não permitir retificação deste campo. |
| numeroTermoContrato | Número do termo de contrato |  | Obrigatório | S |  | Permitir |
| retificacao | Informa se é o caso de retificação de informação já prestada na Fase IV - AUDESP. | true, false | Obrigatório | N | Verificar se informação já foi prestada (codigoTermoContrato) | Não permitir retificação deste campo. |
| objetoTermoContrato | Descrição do objeto do termo de contrato |  | Obrigatório | S |  | Permitir |
| dataAssinatura | Data de assinaturado termo de contrato |  | Obrigatório | S | Data deve ser anterior à data atual. | Permitir |
| qualificacaoAcrescimoSupressao | Identifica se o termo aditivo terá acréscimo/supressão | true, false | Obrigatório | S |  | Permitir |
| qualificacaoVigencia | Identifica se o termo aditivo terá alteração na vigência e número de parcela | true, false | Obrigatório | S |  | Permitir |
| qualificacaoFornecedor | Identifica se o termo aditivo terá alteração do fornecedor | true, false | Obrigatório | S |  | Permitir |
| qualificacaoReajuste | Identifica se o termo aditivo altera valor unitário do item do contrato | true, false | Obrigatório | S |  | Permitir |
| qualificacaoInformativo | Identifica se o termo aditivo tem alguma observação | true, false | Facultativo | S |  | Permitir |
| niFornecedor | Númerode identificaçãodo do fornecedor/arrematante: CNPJ; CPF ou identificador de empresa estrangeira |  | Obrigatório se "qualificacaoFornecedor" = True | S | Validar se é CNPJ/CPF válido, se "tipoPessoaFornecedor" = "PJ" ou "PF" | Permitir |
| tipoPessoaFornecedor |  | PJ - Pessoa jurídica; PF - Pessoa física; PE - Pessoa estrangeira; | Obrigatório | S |  | Permitir |
| nomeRazaoSocialFornecedor  | Nome ou razão social do fornecedor/arrematante  |  | Obrigatório | S |  | Permitir |
| niFornecedorSubContratado  | Número de identificação do fornecedor subcontratado; CNPJ, CPF ou identificador de empresa estrangeira; Somente em caso de subcontratação;  |  | Facultativo | S |  | Permitir |
| TipoPessoaFornecedorSubContratado  |  | PJ - Pessoa jurídica; PF - Pessoa física; PE - Pessoa estrangeira; Somente em caso de subcontratação;  | Facultativo | S |  | Permitir |
| nomeRazaoSocialFornecedorSubContratado  | Nome ou razão social do fornecedor subcontratado; Somente em caso de subcontratação;  |  | Facultativo | S |  | Permitir |
| informativoObservacao  | Observação do termo aditivo  |  | Facultativo | S |  | Permitir |
| fundamentoLegal  | Fundamento legal do termo de contrato  |  | Facultativo | S |  | Permitir |
| valorAcrescido  | Valor acrescido ou suprimido do contrato original; Precisão de 4 dígitos decimais; Ex: 100.0000 ou -100.0000;  |  | Obrigatório se "qualificacaoAcrescimoSupressao" = True | S | Valor diferente de zero | Permitir |
| numeroParcelas  | Número de parcelas; Precisão de 4 dígitos decimais; Ex: 100.0000;  |  | Facultativo | S |  | Permitir |
| valorParcela  | Valor da parcela; Precisão de 4 dígitos decimais; Ex: 100.0000;  |  | Facultativo | S |  | Permitir |
| valorGlobal | Valor global do termo de contrato; Valor da parcela x Número de parcelas; Precisão de 4 dígitos decimais; Ex: 100.0000;  |  | Obrigatório | S | Somente valores acima de zero. | Permitir |
| prazoAditadoDias  | Prazo aditado em dias , diferente de zero |  | Obrigatório | S | Somente números inteiros | Permitir |
| dataVigenciaInicio  | Data de início de vigência do contrato  |  | Obrigatório | S |  | Permitir |
| dataVigenciaFim  | Data do término da vigência do contrato  |  | Obrigatório | S | Devee ser posterior à "dataVigenciaInicio" | Permitir |

# DOMÍNIOS

## Domínio AUDESP: Veículo de Comunicação

| Código | Descrição |
|--------|-----------|
| 1 | Diário Oficial do Município |
| 2 | Diário Oficial do Estado |
| 3 | Diário Oficial da União |
| 4 | Diário da Justiça Eletrônico |
| 5 | Portal Nacional de Compras Públicas |
| 6 | Jornal de grande circulação nacional |
| 7 | Jornal de grande circulação regional/municipal |
| 8 | Quadro ou mural de acesso público |
| 9 | Site da administração direta na Internet |
| 10 | Outros |
|  |  |

## Domínio PNCP: Instrumento Convocatório

| Código | Descrição | Regra referente ao campo Modalidade de Contratação |
|--------|-----------|----------------------------------------------------|
| 1 | Edital: Instrumento convocatório utilizado no leilão, no diálogo competitivo, no concurso, na concorrência e no pregão. | 1, 2, 3, 4, 5, 6, 7, 13, 14, 997, 998 ou 999 |
| 2 | Aviso de Contratação Direta: Instrumento convocatório utilizado na Dispensa com Disputa. | 8 ou 14 |
| 3 | Ato que autoriza a Contratação Direta: Instrumento convocatório utilizado na Dispensa sem Disputa ou na Inexigibilidade. | 8, 9 ou 14 |
| 4 | Edital de Chamamento Público: Instrumento convocatório utilizado para processos auxiliares de manifestação de interesse, de pré-qualificação e de credenciamento.  | 12 ou 14 |
|  |  |  |

## Domínio PNCP com alterações AUDESP: Modalidade de Contratação

| Código | Descrição |
|--------|-----------|
| 1 | Leilão - Eletrônico |
| 2 | Diálogo Competitivo |
| 3 | Concurso |
| 4 | Concorrência - Eletrônica |
| 5 | Concorrência - Presencial |
| 6 | Pregão - Eletrônico |
| 7 | Pregão - Presencial |
| 8 | Dispensa de Licitação |
| 9 | Inexigibilidade |
| 12 | Credenciamento |
| 13 | Leilão - Presencial |
| 14 | Inaplicabilidade da Licitação |
| 997 | Regime Diferenciado de Contratação (RDC) |
| 998 | Convite |
| 999 | Tomada de Preços |
|  |  |

## Domínio PNCP: Modo de Disputa

| Código | Descrição |
|--------|-----------|
| 1 | Aberto |
| 2 | Fechado |
| 3 | Aberto-Fechado |
| 4 | Dispensa com Disputa |
| 5 | Não se aplica |
| 6 | Fechado-Aberto |
|  |  |

## Domínio PNCP com alterações AUDESP: Amparo Legal

| Código | Descrição | Descrição.1 | Regra PNCP, não implementada no AUDESP, referente ao campo Modalidade de Contratação |
|--------|-----------|-------------|--------------------------------------------------------------------------------------|
| 1 |  Lei 14.133/2021, Art. 28, I | pregão: modalidade de licitação obrigatória para aquisição de bens e serviços comuns | 6 ou 7 |
| 2 |  Lei 14.133/2021, Art. 28, II | concorrência: modalidade de licitação para contratação de bens e serviços especiais e de obras e serviços comuns e especiais de engenharia | 4 ou 5 |
| 3 |  Lei 14.133/2021, Art. 28, III | concurso: modalidade de licitação para escolha de trabalho técnico, científico ou artístico, cujo critério de julgamento será o de melhor técnica ou conteúdo artístico, e para concessão de prêmio ou remuneração ao vencedor | 3 |
| 4 |  Lei 14.133/2021, Art. 28, IV | Leilão: modalidade de licitação para alienação de bens imóveis ou de bens móveis inservíveis ou legalmente apreendidos a quem oferecer o maior lance | 1 ou 13 |
| 5 |  Lei 14.133/2021, Art. 28, V | diálogo competitivo: modalidade de licitação para contratação de obras, serviços e compras em que a Administração Pública realiza diálogos com licitantes previamente selecionados mediante critérios objetivos, com o intuito de desenvolver uma ou mais alternativas capazes de atender às suas necessidades, devendo os licitantes apresentar proposta final após o encerramento dos diálogos | 2 |
| 6 |  Lei 14.133/2021, Art. 74, I | Inexigibilidade de Licitação: aquisição de materiais, de equipamentos ou de gêneros ou contratação de serviços que só possam ser fornecidos por produtor, empresa ou representante comercial exclusivos | 9 |
| 7 |  Lei 14.133/2021, Art. 74, II | Inexigibilidade de Licitação: contratação de profissional do setor artístico, diretamente ou por meio de empresário exclusivo, desde que consagrado pela crítica especializada ou pela opinião pública | 9 |
| 8 |  Lei 14.133/2021, Art. 74, III, a | Inexigibilidade de Licitação: a) estudos técnicos, planejamentos, projetos básicos ou projetos executivos. | 9 |
| 9 |  Lei 14.133/2021, Art. 74, III, b | Inexigibilidade de Licitação: b) pareceres, perícias e avaliações em geral. | 9 |
| 10 |  Lei 14.133/2021, Art. 74, III, c | Inexigibilidade de Licitação: c) assessorias ou consultorias técnicas e auditorias financeiras ou tributárias. | 9 |
| 11 |  Lei 14.133/2021, Art. 74, III, d | Inexigibilidade de Licitação: d) fiscalização, supervisão ou gerenciamento de obras ou serviços; | 9 |
| 12 |  Lei 14.133/2021, Art. 74, III, e | Inexigibilidade de Licitação: e) patrocínio ou defesa de causas judiciais ou administrativas; | 9 |
| 13 |  Lei 14.133/2021, Art. 74, III, f | Inexigibilidade de Licitação: f) treinamento e aperfeiçoamento de pessoal | 9 |
| 14 |  Lei 14.133/2021, Art. 74, III, g | Inexigibilidade de Licitação: g) restauração de obras de arte e de bens de valor histórico | 9 |
| 15 |  Lei 14.133/2021, Art. 74, III, h | Inexigibilidade de Licitação: h) controles de qualidade e tecnológico, análises, testes e ensaios de campo e laboratoriais, instrumentação e monitoramento de parâmetros específicos de obras e do meio ambiente e demais serviços de engenharia que se enquadrem no disposto neste inciso | 9 |
| 16 |  Lei 14.133/2021, Art. 74, IV | Inexigibilidade de Licitação: objetos que devam ou possam ser contratados por meio de credenciamento | 12 |
| 17 |  Lei 14.133/2021, Art. 74, V | Inexigibilidade de Licitação: aquisição ou locação de imóvel cujas características de instalações e de localização tornem necessária sua escolha. | 9 |
| 18 |  Lei 14.133/2021, Art. 75, I | Dispensa de Licitação: para contratação que envolva valores inferiores a R$ 100.000,00 (cem mil reais), no caso de obras e serviços de engenharia ou de serviços de manutenção de veículos automotores | 8 |
| 19 |  Lei 14.133/2021, Art. 75, II | Dispensa de Licitação: para contratação que envolva valores inferiores a R$ 50.000,00 (cinquenta mil reais), no caso de outros serviços e compras | 8 |
| 20 |  Lei 14.133/2021, Art. 75, III, a | Dispensa de Licitação: não surgiram licitantes interessados ou não foram apresentadas propostas válidas | 8 |
| 21 |  Lei 14.133/2021, Art. 75, III, b | Dispensa de Licitação: as propostas apresentadas consignaram preços manifestamente superiores aos praticados no mercado ou incompatíveis com os fixados pelos órgãos oficiais competentes | 8 |
| 22 |  Lei 14.133/2021, Art. 75, IV, a | Dispensa de Licitação: bens, componentes ou peças de origem nacional ou estrangeira necessários à manutenção de equipamentos, a serem adquiridos do fornecedor original desses equipamentos durante o período de garantia técnica, quando essa condição de exclusividade for indispensável para a vigência da garantia | 8 |
| 23 |  Lei 14.133/2021, Art. 75, IV, b | Dispensa de Licitação: bens, serviços, alienações ou obras, nos termos de acordo internacional específico aprovado pelo Congresso Nacional, quando as condições ofertadas forem manifestamente vantajosas para a Administração | 8 |
| 24 |  Lei 14.133/2021, Art. 75, IV, c | Dispensa de Licitação: produtos para pesquisa e desenvolvimento, limitada a contratação, no caso de obras e serviços de engenharia, ao valor de R$ 300.000,00 (trezentos mil reais) | 8 |
| 25 |  Lei 14.133/2021, Art. 75, IV, d | Dispensa de Licitação: transferência de tecnologia ou licenciamento de direito de uso ou de exploração de criação protegida, nas contratações realizadas por instituição científica, tecnológica e de inovação (ICT) pública ou por agência de fomento, desde que demonstrada vantagem para a Administração | 8 |
| 26 |  Lei 14.133/2021, Art. 75, IV, e | Dispensa de Licitação: hortifrutigranjeiros, pães e outros gêneros perecíveis, no período necessário para a realização dos processos licitatórios correspondentes, hipótese em que a contratação será realizada diretamente com base no preço do dia. | 8 |
| 27 |  Lei 14.133/2021, Art. 75, IV, f | Dispensa de Licitação: bens ou serviços produzidos ou prestados no País que envolvam, cumulativamente, alta complexidade tecnológica e defesa nacional; | 8 |
| 28 |  Lei 14.133/2021, Art. 75, IV, g | Dispensa de Licitação: materiais de uso das Forças Armadas, com exceção de materiais de uso pessoal e administrativo, quando houver necessidade de manter a padronização requerida pela estrutura de apoio logístico dos meios navais, aéreos e terrestres, mediante autorização por ato do comandante da força militar; | 8 |
| 29 |  Lei 14.133/2021, Art. 75, IV, h | Dispensa de Licitação: bens e serviços para atendimento dos contingentes militares das forças singulares brasileiras empregadas em operações de paz no exterior, hipótese em que a contratação deverá ser justificada quanto ao preço e à escolha do fornecedor ou executante e ratificada pelo comandante da força militar; | 8 |
| 30 |  Lei 14.133/2021, Art. 75, IV, i | Dispensa de Licitação: abastecimento ou suprimento de efetivos militares em estada eventual de curta duração em portos, aeroportos ou localidades diferentes de suas sedes, por motivo de movimentação operacional ou de adestramento | 8 |
| 31 |  Lei 14.133/2021, Art. 75, IV, j | Dispensa de Licitação: coleta, processamento e comercialização de resíduos sólidos urbanos recicláveis ou reutilizáveis, em áreas com sistema de coleta seletiva de lixo, realizados por associações ou cooperativas formadas exclusivamente de pessoas físicas de baixa renda reconhecidas pelo poder público como catadores de materiais recicláveis, com o uso de equipamentos compatíveis com as normas técnicas, ambientais e de saúde pública | 8 |
| 32 |  Lei 14.133/2021, Art. 75, IV, k | Dispensa de Licitação: aquisição ou restauração de obras de arte e objetos históricos, de autenticidade certificada, desde que inerente às finalidades do órgão ou com elas compatível | 8 |
| 33 |  Lei 14.133/2021, Art. 75, IV, l | Dispensa de Licitação: serviços especializados ou aquisição ou locação de equipamentos destinados ao rastreamento e à obtenção de provas previstas nos incisos II e V do caput do art. 3º da Lei nº 12.850, de 2 de agosto de 2013, quando houver necessidade justificada de manutenção de sigilo sobre a investigação | 8 |
| 34 |  Lei 14.133/2021, Art. 75, IV, m | Dispensa de Licitação: aquisição de medicamentos destinados exclusivamente ao tratamento de doenças raras definidas pelo Ministério da Saúde | 8 |
| 35 |  Lei 14.133/2021, Art. 75, V | Dispensa de Licitação: para contratação com vistas ao cumprimento do disposto nos arts. 3º, 3º-A, 4º, 5º e 20 da Lei nº 10.973, de 2 de dezembro de 2004, observados os princípios gerais de contratação constantes da referida Lei | 8 |
| 36 |  Lei 14.133/2021, Art. 75, VI | Dispensa de Licitação: para contratação que possa acarretar comprometimento da segurança nacional, nos casos estabelecidos pelo Ministro de Estado da Defesa, mediante demanda dos comandos das Forças Armadas ou dos demais ministérios | 8 |
| 37 |  Lei 14.133/2021, Art. 75, VII | Dispensa de Licitação: os casos de guerra, estado de defesa, estado de sítio, intervenção federal ou de grave perturbação da ordem | 8 |
| 38 |  Lei 14.133/2021, Art. 75, VIII | Dispensa de Licitação: nos casos de emergência ou de calamidade pública, quando caracterizada urgência de atendimento de situação que possa ocasionar prejuízo ou comprometer a continuidade dos serviços públicos ou a segurança de pessoas, obras, serviços, equipamentos e outros bens, públicos ou particulares, e somente para aquisição dos bens necessários ao atendimento da situação emergencial ou calamitosa e para as parcelas de obras e serviços que possam ser concluídas no prazo máximo de 1 (um) ano, contado da data de ocorrência da emergência ou da calamidade, vedadas a prorrogação dos respectivos contratos e a recontratação de empresa já contratada com base no disposto neste inciso | 8 |
| 39 |  Lei 14.133/2021, Art. 75, IX | Dispensa de Licitação: para a aquisição, por pessoa jurídica de direito público interno, de bens produzidos ou serviços prestados por órgão ou entidade que integrem a Administração Pública e que tenham sido criados para esse fim específico, desde que o preço contratado seja compatível com o praticado no mercado | 8 |
| 40 |  Lei 14.133/2021, Art. 75, X | Dispensa de Licitação: quando a União tiver que intervir no domínio econômico para regular preços ou normalizar o abastecimento | 8 |
| 41 |  Lei 14.133/2021, Art. 75, XI | Dispensa de Licitação: para celebração de contrato de programa com ente federativo ou com entidade de sua Administração Pública indireta que envolva prestação de serviços públicos de forma associada nos termos autorizados em contrato de consórcio público ou em convênio de cooperação | 8 |
| 42 |  Lei 14.133/2021, Art. 75, XII | Dispensa de Licitação: para contratação em que houver transferência de tecnologia de produtos estratégicos para o Sistema Único de Saúde (SUS), conforme elencados em ato da direção nacional do SUS, inclusive por ocasião da aquisição desses produtos durante as etapas de absorção tecnológica, e em valores compatíveis com aqueles definidos no instrumento firmado para a transferência de tecnologia | 8 |
| 43 |  Lei 14.133/2021, Art. 75, XIII | Dispensa de Licitação: para contratação de profissionais para compor a comissão de avaliação de critérios de técnica, quando se tratar de profissional técnico de notória especialização | 8 |
| 44 |  Lei 14.133/2021, Art. 75, XIV | Dispensa de Licitação: para contratação de associação de pessoas com deficiência, sem fins lucrativos e de comprovada idoneidade, por órgão ou entidade da Administração Pública, para a prestação de serviços, desde que o preço contratado seja compatível com o praticado no mercado e os serviços contratados sejam prestados exclusivamente por pessoas com deficiência | 8 |
| 45 |  Lei 14.133/2021, Art. 75, XV | Dispensa de Licitação: para contratação de instituição brasileira que tenha por finalidade estatutária apoiar, captar e executar atividades de ensino, pesquisa, extensão, desenvolvimento institucional, científico e tecnológico e estímulo à inovação, inclusive para gerir administrativa e financeiramente essas atividades, ou para contratação de instituição dedicada à recuperação social da pessoa presa, desde que o contratado tenha inquestionável reputação ética e profissional e não tenha fins lucrativos | 8 |
| 46 |  Lei 14.133/2021, Art. 75, XVI | Dispensa de Licitação: para aquisição, por pessoa jurídica de direito público interno, de insumos estratégicos para a saúde produzidos por fundação que, regimental ou estatutariamente, tenha por finalidade apoiar órgão da Administração Pública direta, sua autarquia ou fundação em projetos de ensino, pesquisa, extensão, desenvolvimento institucional, científico e tecnológico e de estímulo à inovação, inclusive na gestão administrativa e financeira necessária à execução desses projetos, ou em parcerias que envolvam transferência de tecnologia de produtos estratégicos para o SUS, nos termos do inciso XII docaputdeste artigo, e que tenha sido criada para esse fim específico em data anterior à entrada em vigor desta Lei, desde que o preço contratado seja compatível com o praticado no mercado | 8 |
| 47 |  Lei 14.133/2021, Art. 78, I | Credenciamento: processo administrativo de chamamento público em que a Administração Pública convoca interessados em prestar serviços ou fornecer bens para que, preenchidos os requisitos necessários, se credenciem no órgão ou na entidade para executar o objeto quando convocados | 12 |
| 50 | Lei 14.133/2021, Art. 74, caput  | Inexigibilidade de Licitação: Todas as formas de inexigibilidade não previstas no art. 74 | 8 |
| 60 |  Lei 14.133/2021, Art. 75, XVII | Dispensa de Licitação: para contratação de entidades privadas sem fins lucrativos para a implementação de cisternas ou outras tecnologias sociais de acesso à água para consumo humano e produção de alimentos, para beneficiar famílias rurais de baixa renda atingidas pela seca ou pela falta regular de água. | 8 |
| 61 | Lei 14.133/2021, Art. 76, I, a  | Art. 76, I, a: Dispensa de Licitação: dação em pagamento | 8 |
| 62 | Lei 14.133/2021, Art. 76, I, b | Dispensa de Licitação: doação, permitida exclusivamente para outro órgão ou entidade da Administração Pública, de qualquer esfera de governo, ressalvado o disposto nas alíneas “f”, “g” e “h” deste inciso | 8 |
| 63 |  Lei 14.133/2021, Art. 76, I, c | Dispensa de Licitação: permuta por outros imóveis que atendam aos requisitos relacionados às finalidades precípuas da Administração, desde que a diferença apurada não ultrapasse a metade do valor do imóvel que será ofertado pela União, segundo avaliação prévia, e ocorra a torna de valores, sempre que for o caso | 8 |
| 64 | Lei 14.133/2021, Art. 76, I, d  | Dispensa de Licitação: investidura | 8 |
| 65 | Lei 14.133/2021, Art. 76, I, d  | Dispensa de Licitação: venda a outro órgão ou entidade da Administração Pública de qualquer esfera de governo | 8 |
| 66 | Lei 14.133/2021, Art. 76, I, f  | Dispensa de Licitação: alienação gratuita ou onerosa, aforamento, concessão de direito real de uso, locação e permissão de uso de bens imóveis residenciais construídos, destinados ou efetivamente usados em programas de habitação ou de regularização fundiária de interesse social desenvolvidos por órgão ou entidade da Administração Pública | 8 |
| 67 | Lei 14.133/2021, Art. 76, I, g  | Dispensa de Licitação: alienação gratuita ou onerosa, aforamento, concessão de direito real de uso, locação e permissão de uso de bens imóveis comerciais de âmbito local, com área de até 250 m² (duzentos e cinquenta metros quadrados) e destinados a programas de regularização fundiária de interesse social desenvolvidos por órgão ou entidade da Administração Pública | 8 |
| 68 | Lei 14.133/2021, Art. 76, I, h  | Dispensa de Licitação: alienação e concessão de direito real de uso, gratuita ou onerosa, de terras públicas rurais da União e do Instituto Nacional de Colonização e Reforma Agrária (Incra) onde incidam ocupações até o limite de que trata o § 1º do art. 6º da Lei nº 11.952, de 25 de junho de 2009, para fins de regularização fundiária, atendidos os requisitos legais | 8 |
| 69 | Lei 14.133/2021, Art. 76, I, i  | Dispensa de Licitação: legitimação de posse de que trata o art. 29 da Lei nº 6.383, de 7 de dezembro de 1976, mediante iniciativa e deliberação dos órgãos da Administração Pública competentes | 8 |
| 70 | Lei 14.133/2021, Art. 76, I, j | Dispensa de Licitação: legitimação fundiária e legitimação de posse de que trata a Lei nº 13.465, de 11 de julho de 2017 | 8 |
| 71 | Lei 14.133/2021, Art. 76, II, a | Dispensa de Licitação: doação, permitida exclusivamente para fins e uso de interesse social, após avaliação de oportunidade e conveniência socioeconômica em relação à escolha de outra forma de alienação | 8 |
| 72 | Lei 14.133/2021, Art. 76, II, b | Dispensa de Licitação: permuta, permitida exclusivamente entre órgãos ou entidades da Administração Pública | 8 |
| 73 | Lei 14.133/2021, Art. 76, II, c  | Dispensa de Licitação: venda de ações, que poderão ser negociadas em bolsa, observada a legislação específica | 8 |
| 74 | Lei 14.133/2021, Art. 76, II, d | Dispensa de Licitação: venda de títulos, observada a legislação pertinente | 8 |
| 75 | Lei 14.133/2021, Art. 76, II, e  | Dispensa de Licitação: venda de bens produzidos ou comercializados por entidades da Administração Pública, em virtude de suas finalidades | 8 |
| 76 | Lei 14.133/2021, Art. 76, II, f  | Dispensa de Licitação: venda de materiais e equipamentos sem utilização previsível por quem deles dispõe para outros órgãos ou entidades da Administração Pública | 8 |
| 77 | Lei 14.133/2021, Art. 75, XVIII  | Dispensa de Licitação: contratação de entidades privadas sem fins lucrativos, para a implementação do Programa Cozinha Solidária, que tem como finalidade fornecer alimentação gratuita preferencialmente à população em situação de vulnerabilidade e risco social, incluída a população em situação de rua, com vistas à promoção de políticas de segurança alimentar e nutricional e de assistência social e à efetivação de direitos sociais, dignidade humana, resgate social e melhoria da qualidade de vida. | 8 |
| 78 | Lei 14.628/2023, Art. 4º | Dispensa de Licitação: O Poder Executivo federal, estadual, distrital e municipal poderá adquirir, dispensada a licitação, os alimentos produzidos pelos beneficiários fornecedores de que trata o art. 5º desta Lei. | 8 |
| 81 | Lei 13.303/2016, Art. 27, § 3º  | Patrocínio: convênio ou contrato de patrocínio com pessoa física ou com pessoa jurídica para promoção de atividades culturais, sociais, esportivas, educacionais e de inovação tecnológica, desde que comprovadamente vinculadas ao fortalecimento de sua marca, observando-se, no que couber, as normas de licitação e contratos desta Lei |  |
| 82 | Lei 13.303/2016, Art. 28, § 3º, I  | Inaplicabilidade de Licitação: comercialização, prestação ou execução, de forma direta, pelas empresas mencionadas no caput , de produtos, serviços ou obras especificamente relacionados com seus respectivos objetos sociais |  |
| 83 |  Lei 13.303/2016, Art. 28, § 3º, II | Inaplicabilidade de Licitação: escolha do parceiro esteja associada a suas características particulares, vinculada a oportunidades de negócio definidas e específicas, justificada a inviabilidade de procedimento competitivo |  |
| 84 | Lei 13.303/2016, Art. 29, I | Dispensa de Licitação: para obras e serviços de engenharia de valor até R$ 100.000,00 (cem mil reais), desde que não se refiram a parcelas de uma mesma obra ou serviço ou ainda a obras e serviços de mesma natureza e no mesmo local que possam ser realizadas conjunta e concomitantemente | 8 |
| 85 | Lei 13.303/2016, Art. 29, II | Dispensa de Licitação: para outros serviços e compras de valor até R$ 50.000,00 (cinquenta mil reais) e para alienações, nos casos previstos nesta Lei, desde que não se refiram a parcelas de um mesmo serviço, compra ou alienação de maior vulto que possa ser realizado de uma só vez | 8 |
| 86 | Lei 13.303/2016, Art. 29, III | Dispensa de Licitação: quando não acudirem interessados à licitação anterior e essa, justificadamente, não puder ser repetida sem prejuízo para a empresa pública ou a sociedade de economia mista, bem como para suas respectivas subsidiárias, desde que mantidas as condições preestabelecidas | 8 |
| 87 | Lei 13.303/2016, Art. 29, IV | Dispensa de Licitação: quando as propostas apresentadas consignarem preços manifestamente superiores aos praticados no mercado nacional ou incompatíveis com os fixados pelos órgãos oficiais competentes; | 8 |
| 88 | Lei 13.303/2016, Art. 29, V | Dispensa de Licitação: para a compra ou locação de imóvel destinado ao atendimento de suas finalidades precípuas, quando as necessidades de instalação e localização condicionarem a escolha do imóvel, desde que o preço seja compatível com o valor de mercado, segundo avaliação prévia; | 8 |
| 89 | Lei 13.303/2016, Art. 29, VI | Dispensa de Licitação: na contratação de remanescente de obra, de serviço ou de fornecimento, em consequência de rescisão contratual, desde que atendida a ordem de classificação da licitação anterior e aceitas as mesmas condições do contrato encerrado por rescisão ou distrato, inclusive quanto ao preço, devidamente corrigido; | 8 |
| 90 | Lei 13.303/2016, Art. 29, VII | Dispensa de Licitação: na contratação de instituição brasileira incumbida regimental ou estatutariamente da pesquisa, do ensino ou do desenvolvimento institucional ou de instituição dedicada à recuperação social do preso, desde que a contratada detenha inquestionável reputação ético-profissional e não tenha fins lucrativos; | 8 |
| 91 | Lei 13.303/2016, Art. 29, VIII | Dispensa de Licitação: para a aquisição de componentes ou peças de origem nacional ou estrangeira necessários à manutenção de equipamentos durante o período de garantia técnica, junto ao fornecedor original desses equipamentos, quando tal condição de exclusividade for indispensável para a vigência da garantia; | 8 |
| 92 | Lei 13.303/2016, Art. 29, IX | Dispensa de Licitação: na contratação de associação de pessoas com deficiência física, sem fins lucrativos e de comprovada idoneidade, para a prestação de serviços ou fornecimento de mão de obra, desde que o preço contratado seja compatível com o praticado no mercado; | 8 |
| 93 | Lei 13.303/2016, Art. 29, X | Dispensa de Licitação: na contratação de concessionário, permissionário ou autorizado para fornecimento ou suprimento de energia elétrica ou gás natural e de outras prestadoras de serviço público, segundo as normas da legislação específica, desde que o objeto do contrato tenha pertinência com o serviço público; | 8 |
| 94 | Lei 13.303/2016, Art. 29, XI | Dispensa de Licitação: nas contratações entre empresas públicas ou sociedades de economia mista e suas respectivas subsidiárias, para aquisição ou alienação de bens e prestação ou obtenção de serviços, desde que os preços sejam compatíveis com os praticados no mercado e que o objeto do contrato tenha relação com a atividade da contratada prevista em seu estatuto social; | 8 |
| 95 | Lei 13.303/2016, Art. 29, XII | Dispensa de Licitação: na contratação de coleta, processamento e comercialização de resíduos sólidos urbanos recicláveis ou reutilizáveis, em áreas com sistema de coleta seletiva de lixo, efetuados por associações ou cooperativas formadas exclusivamente por pessoas físicas de baixa renda que tenham como ocupação econômica a coleta de materiais recicláveis, com o uso de equipamentos compatíveis com as normas técnicas, ambientais e de saúde pública; | 8 |
| 96 | Lei 13.303/2016, Art. 29, XIII | Dispensa de Licitação: para o fornecimento de bens e serviços, produzidos ou prestados no País, que envolvam, cumulativamente, alta complexidade tecnológica e defesa nacional, mediante parecer de comissão especialmente designada pelo dirigente máximo da empresa pública ou da sociedade de economia mista; | 8 |
| 97 | Lei 13.303/2016, Art. 29, XIV | Dispensa de Licitação: nas contratações visando ao cumprimento do disposto nos arts. 3º, 4º, 5º e 20 da Lei nº 10.973, de 2 de dezembro de 2004 , observados os princípios gerais de contratação dela constantes; | 8 |
| 98 | Lei 13.303/2016, Art. 29, XV | Dispensa de Licitação: em situações de emergência, quando caracterizada urgência de atendimento de situação que possa ocasionar prejuízo ou comprometer a segurança de pessoas, obras, serviços, equipamentos e outros bens, públicos ou particulares, e somente para os bens necessários ao atendimento da situação emergencial e para as parcelas de obras e serviços que possam ser concluídas no prazo máximo de 180 (cento e oitenta) dias consecutivos e ininterruptos, contado da ocorrência da emergência, vedada a prorrogação dos respectivos contratos, observado o disposto no § 2º; | 8 |
| 99 | Lei 13.303/2016, Art. 29, XVI | Dispensa de Licitação: na transferência de bens a órgãos e entidades da administração pública, inclusive quando efetivada mediante permuta; | 8 |
| 100 | Lei 13.303/2016, Art. 29, XVII | Dispensa de Licitação: na doação de bens móveis para fins e usos de interesse social, após avaliação de sua oportunidade e conveniência socioeconômica relativamente à escolha de outra forma de alienação; | 8 |
| 101 | Lei 13.303/2016, Art. 29, XVIII | Dispensa de Licitação: na compra e venda de ações, de títulos de crédito e de dívida e de bens que produzam ou comercializem. | 8 |
| 102 | Lei 13.303/2016, Art. 30, caput - inexigibilidade | Inexigibilidade de Licitação: Inviabilidade de competição; | 9 |
| 103 | Lei 13.303/2016, Art. 30, caput - credenciamento | Credenciamento de Empresa/autonomos | 12 |
| 104 | Lei 13.303/2016, Art. 30, I | Inexigibilidade de Licitação: aquisição de materiais, equipamentos ou gêneros que só possam ser fornecidos por produtor, empresa ou representante comercial exclusivo; | 9 |
| 105 | Lei 13.303/2016, Art. 30, II, a | Inexigibilidade de Licitação: a) estudos técnicos, planejamentos e projetos básicos ou executivos; | 9 |
| 106 | Lei 13.303/2016, Art. 30, II, b | Inexigibilidade de Licitação: b) pareceres, perícias e avaliações em geral; | 9 |
| 107 | Lei 13.303/2016, Art. 30, II, c | Inexigibilidade de Licitação: c) assessorias ou consultorias técnicas e auditorias financeiras ou tributárias; | 9 |
| 108 | Lei 13.303/2016, Art. 30, II, d | Inexigibilidade de Licitação: d) fiscalização, supervisão ou gerenciamento de obras ou serviços; | 9 |
| 109 | Lei 13.303/2016, Art. 30, II, e | Inexigibilidade de Licitação: e) patrocínio ou defesa de causas judiciais ou administrativas; | 9 |
| 110 | Lei 13.303/2016, Art. 30, II, f | Inexigibilidade de Licitação: f) treinamento e aperfeiçoamento de pessoal; | 9 |
| 111 | Lei 13.303/2016, Art. 30, II, g | Inexigibilidade de Licitação: g) restauração de obras de arte e bens de valor histórico. | 9 |
| 112 | Lei 13.303/2016, Art. 31, § 4º  | Manifestação de Interesse Privado: procedimento adotado para o recebimento de propostas e projetos de empreendimentos com vistas a atender necessidades previamente identificadas, cabendo a regulamento a definição de suas regras específicas. |  |
| 113 | Lei 13.303/2016, Art. 32, IV | Pregão: modalidade de licitação preferencial para a aquisição de bens e serviços comuns, assim considerados aqueles cujos padrões de desempenho e qualidade possam ser objetivamente definidos pelo edital, por meio de especificações usuais no mercado; |  |
| 114 | Lei 13.303/2016, Art. 54, I | Licitação: menor preço |  |
| 115 | Lei 13.303/2016, Art. 54, II | Licitação: maior desconto |  |
| 116 | Lei 13.303/2016, Art. 54, III | Licitação: melhor combinação de técnica e preço |  |
| 117 | Lei 13.303/2016, Art. 54, IV | Licitação: melhor técnica |  |
| 118 | Lei 13.303/2016, Art. 54, V | Licitação: melhor conteúdo artístico |  |
| 119 | Lei 13.303/2016, Art. 54, VI | Licitação: maior oferta de preço |  |
| 120 | Lei 13.303/2016, Art. 54, VII | Licitação: maior retorno econômico |  |
| 121 | Lei 13.303/2016, Art. 54, VIII | Licitação: melhor destinação de bens alienados |  |
| 122 | Lei 13.303/2016, Art. 63, I | Pré-qualificação permanente |  |
| 123 | Lei 13.303/2016, Art. 63, III | Sistema de registro de preços |  |
| 124 | Regulamento Interno de Licitações e Contratos Estatais - diálogo competitivo  | Licitação: diálogo competitivo | 2 |
| 125 | Regulamento Interno de Licitações e Contratos Estatais - credenciamento  | Inexigibilidade de Licitação: credenciamento | 12 |
| 126 | Lei 12.850/2013, Art. 3º, §1º, II  | Dispensa de Licitação: contratação de serviços técnicos especializados, aquisição ou locação de equipamentos destinados à polícia judiciária para o rastreamento e obtenção de provas por meio de captação ambiental de sinais eletromagnéticos, ópticos ou acústicos | 8 |
| 127 | Lei 12.850/2013, Art. 3º, §1º, V | Dispensa de Licitação: contratação de serviços técnicos especializados, aquisição ou locação de equipamentos destinados à polícia judiciária para o rastreamento e obtenção de provas por meio de interceptação de comunicações telefônicas e telemáticas, nos termos da legislação específica | 8 |
| 128 | Lei 13.529/2017, Art. 5º | Dispensa de Licitação: para desenvolver, com recursos do fundo, as atividades e os serviços técnicos necessários para viabilizar a licitação de projetos de concessão e de parceria público-privada |  |
| 129 | Lei 8.629/1993, Art. 17, § 3º, V | Dispensa de Licitação: contratação de instituição financeira para operacionalização da reforma agrária |  |
| 130 | Lei 10.847/2004, Art. 6º | Dispensa de Licitação: É dispensada de licitação a contratação da EPE por órgãos ou entidades da administração pública com vistas na realização de atividades integrantes de seu objeto |  |
| 131 | Lei 11.516/2007, Art. 14-A | Dispensa de Licitação: selecionar instituição financeira oficial, dispensada a licitação, para criar e administrar fundo privado a ser integralizado com recursos oriundos da compensação ambiental de que trata o art. 36 da Lei nº 9.985, de 18 de julho de 2000, destinados às unidades de conservação instituídas pela União |  |
| 132 |  Lei 11.652/2008, Art. 8º, § 2º, I | Dispensa de Licitação: I - celebração dos ajustes com vistas na formação da Rede Nacional de Comunicação Pública mencionados no inciso III do caput deste artigo, que poderão ser firmados, em igualdade de condições, com entidades públicas ou privadas que explorem serviços de comunicação ou radiodifusão, por até 10 (dez) anos, renováveis por iguais períodos; |  |
| 133 | Lei 11.652/2008, Art. 8º, § 2º, II | Dispensa de Licitação: II - contratação da EBC por órgãos e entidades da administração pública, com vistas na realização de atividades relacionadas ao seu objeto, desde que o preço contratado seja compatível com o de mercado. |  |
| 134 | Lei 11.759/2008, Art. 18-A | Dispensa de Licitação: contratação da Ceitec por órgãos e entidades da administração pública para a realização de atividades relacionadas a seu objeto. |  |
| 135 | Lei 12.865/2013, Art. 18, § 1º | Dispensa de Licitação: a União, por intermédio da Secretaria de Políticas para as Mulheres da Presidência da República (SPM/PR), autorizada a contratar o Banco do Brasil S.A. ou suas subsidiárias para atuar na gestão de recursos, obras e serviços de engenharia relacionados ao desenvolvimento de projetos, modernização, ampliação, construção ou reforma da rede integrada e especializada para atendimento da mulher em situação de violência. |  |
| 136 | Lei 12.873/2013, Art. 42 | Dispensa de Licitação: Fica o Ministério da Saúde autorizado a contratar, mediante dispensa de licitação, instituição financeira oficial federal para realizar atividades relacionadas à avaliação dos planos de recuperação econômica e financeira apresentados pelas entidades de saúde para adesão ao Prosus. |  |
| 137 | 137) Lei 13.979/2020, Art. 4º, § 1º | Dispensa de Licitação: É dispensável a licitação para aquisição ou contratação de bens, serviços, inclusive de engenharia, e insumos destinados ao enfrentamento da emergência de saúde pública de importância internacional de que trata esta Lei. |  |
| 138 | Lei 11.947/2009, Art. 14, 1º | Dispensa de Licitação: aquisição de gêneros alimentícios diretamente da agricultura familiar e do empreendedor familiar rural ou de suas organizações, priorizando-se os assentamentos da reforma agrária, as comunidades tradicionais indígenas, as comunidades quilombolas e os grupos formais e informais de mulheres. |  |
| 139 | Lei 11.947/2009, Art. 21 | Dispensa de Licitação: aquisição emergencial dos gêneros alimentícios, mantidas as demais regras estabelecidas para execução do PNAE, inclusive quanto à prestação de contas. |  |
| 140 | Lei 14.133/2021, Art. 79, I | Credenciamento: na hipótese de contratação paralela e não excludente: caso em que é viável e vantajosa para a Administração a realização de contratações simultâneas em condições padronizadas. |  |
| 141 | Lei 14.133/2021, Art. 79, II | Credenciamento: na hipótese de contratação com seleção a critério de terceiros: caso em que a seleção do contratado está a cargo do beneficiário direto da prestação. |  |
| 142 | Lei 14.133/2021, Art. 79, III | Credenciamento: na hipótese de contratação em mercados fluidos: caso em que a flutuação constante do valor da prestação e das condições de contratação inviabiliza a seleção de agente por meio de processo de licitação. |  |
| 143 | Lei 14.133/2021, art. 26, §1º, II | Margem de preferência: Estabelece uma margem de preferência para bens manufaturados e serviços nacionais ou bens reciclados, recicláveis ou biodegradáveis, que estejam em conformidade com as normas técnicas brasileiras. Isso incentiva a produção e o desenvolvimento de produtos e serviços dentro do país. |  |
| 144 | Lei 14.133/2021, art. 26, §2º | Margem de preferência: Estabelece uma margem de preferência adicional para bens manufaturados e serviços nacionais ou bens reciclados, recicláveis ou biodegradáveis, que estejam em conformidade com as normas técnicas brasileiras. Isso incentiva a produção e o desenvolvimento de produtos e serviços dentro do país. |  |
| 145 | Lei 14.133/2021, art. 60, I | Critério de desempate: Estipula que, em caso de empate entre propostas de licitação, os licitantes envolvidos devem participar de uma disputa final onde podem apresentar novas propostas imediatamente após a classificação, proporcionando uma chance adicional para vencer a licitação. |  |
| 146 | Lei 14.133/2021, art. 60, §1º, I | Critério de desempate: Prioriza, em situações de empate onde nenhum outro critério resolve, as empresas localizadas no território do Estado ou Distrito Federal do órgão licitante, ou, em licitações municipais, no Estado onde o município está situado. |  |
| 147 | Lei 14.133/2021, art. 60, §1º, II | Critério de desempate: Concede preferência secundária, após a localização geográfica da empresa, às empresas brasileiras em caso de empate persistente, reforçando o apoio à indústria nacional. |  |
| 148 | Lei 14.133/2021, art. 60, outros incisos | Critério de desempate: Utilizar esse código quando a justificativa de desempate via art. 60, derivar de outros incisos da Lei 14.133/2021 que não estão previstos nos Amparos Legais, códigos 145; 146; e 147, constantes no Manual de Integração do PNCP em seu item 5.15. Amparo Legal. |  |
| 149 | MP nº 1.221/2024, art. 2º, I (Calamidade pública) | MEDIDA PROVISÓRIA Nº 1.221, DE 17 DE MAIO DE 2024. Dispensa de Licitação: aquisição de bens, a contratação de obras e de serviços, inclusive de engenharia, observado o disposto no Capítulo III. |  |
| 150 | MP nº 1.221/2024, art. 2º, IV (Calamidade pública) | MEDIDA PROVISÓRIA Nº 1.221, DE 17 DE MAIO DE 2024. Contrato: firmar contrato verbal, nos termos do disposto no § 2º do art. 95 da Lei nº 14.133, de 2021, desde que o seu valor não seja superior a R$ 100.000,00 (cem mil reais), nas hipóteses em que a urgência não permitir a formalização do instrumento contratual. |  |
| 151 | MP nº 1.221/2024, art. 2º, II (Calamidade pública) | MEDIDA PROVISÓRIA Nº 1.221, DE 17 DE MAIO DE 2024. Reduzir pela metade os prazos mínimos de que tratam o art. 55 e o § 3º do art. 75 da Lei nº 14.133, de 2021, para a apresentação das propostas e dos lances, nas licitações ou nas contratações diretas com disputa eletrônica. |  |
| 152 | Lei 6.855/1980, art. 30, §3º  | Dispensa de licitação: venda ou permuta de imóveis da União, das Entidades da Administração Indireta, e de Fundações criadas por lei, a serem adquiridos pela Fundação Habitacional do Exército, inclusive com recursos orçamentários. |  |
| 153 | Lei 11.652/2008, art. 8º, §2º, I | Dispensa de licitação: celebração dos ajustes com vistas na formação da Rede Nacional de Comunicação Pública mencionados no inciso III do caput deste artigo, que poderão ser firmados, em igualdade de condições, com entidades públicas ou privadas que explorem serviços de comunicação ou radiodifusão, por até 10 (dez) anos, renováveis por iguais períodos. |  |
| 154 | Lei 11.652/2008, art. 8º, §2º, II | Dispensa de licitação: contratação da EBC por órgãos e entidades da administração pública, com vistas na realização de atividades relacionadas ao seu objeto, desde que o preço contratado seja compatível com o de mercado. |  |
| 155 | Lei 14.744/2023, art 2º, I | Dispensa de licitação: Empresa Brasileira de Correios e Telégrafos, para a prestação e a utilização de serviços postais não exclusivos, definidos expressamente no Decreto-Lei nº 509, de 20 de março de 1969, e na Lei nº 6.538, de 22 de junho de 1978. |  |
| 156 | Lei 14.744/2023, art 2º, II | Dispensa de licitação: Telecomunicações Brasileiras S.A., para utilização de serviços de comunicação multimídia regidos pela Lei nº 9.472, de 16 de julho de 1997. |  |
| 157 | Instrução normativa de critério de julgamento e/ou edital (Sorteio) | Critério de desempate: Realização de sorteio. |  |
| 964 | Lei 8666/1993, Art. 25, III |  | 9 |
| 965 | Lei 8666/1993, Art. 25, II |  | 9 |
| 966 | Lei 8666/1993, Art. 25, I |  | 9 |
| 967 | Lei 8666/1993, Art. 25, caput |  | 9 |
| 968 | Lei 8666/1993, Art. 24, XXXIII |  | 8 |
| 969 | Lei 8666/1993, Art. 24, XXXII |  | 8 |
| 970 | Lei 8666/1993, Art. 24, XXXI |  | 8 |
| 971 | Lei 8666/1993, Art. 24, XXX |  | 8 |
| 972 | Lei 8666/1993, Art. 24, XXVII |  | 8 |
| 973 | Lei 8666/1993, Art. 24, XXVI |  | 8 |
| 974 | Lei 8666/1993, Art. 24, XXV |  | 8 |
| 975 | Lei 8666/1993, Art. 24, XXIV |  | 8 |
| 976 | Lei 8666/1993, Art. 24, XXIII |  | 8 |
| 977 | Lei 8666/1993, Art. 24, XXII |  | 8 |
| 978 | Lei 8666/1993, Art. 24, XXI |  | 8 |
| 979 | Lei 8666/1993, Art. 24, XX |  | 8 |
| 980 | Lei 8666/1993, Art. 24, XVIII |  | 8 |
| 981 | Lei 8666/1993, Art. 24, XVI |  | 8 |
| 982 | Lei 8666/1993, Art. 24, XVI |  | 8 |
| 983 | Lei 8666/1993, Art. 24, XV |  | 8 |
| 984 | Lei 8666/1993, Art. 24, XIV |  | 8 |
| 985 | Lei 8666/1993, Art. 24, XIII |  | 8 |
| 986 | Lei 8666/1993, Art. 24, XII |  | 8 |
| 987 | Lei 8666/1993, Art. 24, XI |  | 8 |
| 988 | Lei 8666/1993, Art. 24, X |  | 8 |
| 989 | Lei 8666/1993, Art. 24, VIII |  | 8 |
| 990 | Lei 8666/1993, Art. 24, VII |  | 8 |
| 991 | Lei 8666/1993, Art. 24, V |  | 8 |
| 992 | Lei 8666/1993, Art. 24, IV |  | 8 |
| 993 | Lei 8666/1993, Art. 24, III |  | 8 |
| 994 | Lei 8666/1993, Art. 24, II |  | 8 |
| 995 | Lei 8666/1993, Art. 24, I |  | 8 |
| 996 | Lei 8666/1993, Art. 17,§2 |  | 1, 4, 5, 8, 9 ou 13 |
| 997 | Lei 8666/1993, Art. 17, II |  | 1, 4, 5, 8, 9 ou 13 |
| 998 | Lei 8666/1993, Art. 17, I |  | 1, 4, 5, 8, 9 ou 13 |
| 999 | Lei 8666/1993, outra opção não elencada acima |  | - |
| 1019 | Lei 14.124/2021, Art. 2º |  | 8 |
| 1020 | Lei 11.947/2009 |  | - |
|  |  |  |  |

## Domínio PNCP: Tipo de Benefício

| Código | Descrição |
|--------|-----------|
| 1 | Participação exclusiva para ME/EPP |
| 2 | Subcontratação para ME/EPP |
| 3 | Cota reservada para ME/EPP |
| 4 | Sem benefício |
| 5 | Não se aplica |
|  |  |

## Domínio PNCP com alterações AUDESP: Critério de julgamento

| Código | Descrição |
|--------|-----------|
| 1 | Menor preço |
| 2 | Maior desconto |
| 4 | Técnica e preço |
| 5 | Maior lance |
| 6 | Maior retorno econômico |
| 7 | Não se aplica |
| 8 | Melhor técnica |
| 9 | Conteúdo artístico |
| 1000 | Melhor destinação de bens alienados |
| 1001 | Maior oferta de preço |
|  |  |

## Domínio AUDESP: Tipo de Natureza

| Código | Descrição | Detalhamento |
|--------|-----------|--------------|
| 1 | Normal | Nenhuma das alternativas abaixo |
| 2 | Concessão/permissão de uso (Lei 14.133/2024) | Permissão pela Administração Pública em que o particular se utiliza de um bem público em troca de algum tipo de remuneração. Trata-se do previsto nos inciso I e IV do Art. 2º da lei 14.133/2024. |
| 3 | Concessão de serviço público ordinária (Lei 8.987/1995) | Concessão na qual a remuneração básica decorre de tarifa paga pelo usuário ou outra forma de remuneração decorrente da própria exploração do serviço (receitas alternativa), conforme previsão na Lei 8.987/1995 e legislação esparsa sobre os serviços públicos específicos. |
| 4 | Concessão Pública - PPP Patrocinada (Lei 11.079/2004) | Concessão em que se conjugam a tarifa paga pelos usuários e a contraprestação pecuniária do concedente (parceiro público) ao concessionário (parceiro privado); ou seja, o concessionário (a empresa que explora a atividade) recebe a tarifa do usuário e um complemento pago pela Administração. Conforme previsão na Lei 11.079/2004. |
| 5 | Concessão Pública - PPP Administrativa (Lei 11.079/2004) | Concessão em que a remuneração básica é constituída por contraprestação feita pelo parceiro público ao parceiro privado. Conforme previsão na Lei 11.079/2004. |
| 6 | Permissão de serviço público (Lei 8.987/1995) | Delegação, a título precário, mediante licitação, da prestação de serviços públicos, feita pelo poder concedente à pessoa física ou jurídica que demonstre capacidade para seu desempenho, por sua conta e risco. Conforme previsão na Lei Lei 8.987/1995. |
| 7 | Credenciamento (Lei 14.133/2021) | Processo administrativo de chamamento público em que a Administração Pública convoca interessados em prestar serviços ou fornecer bens para que, preenchidos os requisitos necessários, se credenciem no órgão ou na entidade para executar o objeto quando convocados. Conforme previsão no Art. 79 da Lei 14.133/2021. |
| 8 | Registro de Preços (Lei 14.133/2021) | Conjunto de procedimentos para realização, mediante contratação direta ou licitação nas modalidades pregão ou concorrência, de registro formal de preços relativos a prestação de serviços, a obras e a aquisição e locação de bens para contratações futuras. Conforme previsão no Art. 82 da Lei 14.133/2021. |
|  |  |  |

## Domínio AUDESP: Fonte de Recursos

| Conforme documentação AUDESP: Anexo II - Tabelas de Escrituração Contábil - Auxiliares |  |  |
|----------------------------------------------------------------------------------------|--|--|
| Código | Descrição | Detalhamento |
| 1 | TESOURO | Recursos próprios gerados pelo Município, ou decorrentes de Cota-Parte Constitucional; |
| 2 | TRANSFERÊNCIAS E CONVÊNIOS ESTADUAIS - VINCULADOS | Recursos originários de transferências estaduais em virtude de assinatura de convênios ou legislações específicas, cuja destinação encontra-se vinculada aos seus objetos; |
| 3 | RECURSOS PRÓPRIOS DE FUNDOS ESPECIAIS DE DESPESA - VINCULADOS | Recursos gerados pelos Fundos Especiais de Despesa ou a eles pertencentes, com destinação vinculada conforme legislação específica de criação de cada Fundo; |
| 4 | RECURSOS PRÓPRIOS DA ADMINISTRAÇÃO INDIRETA | Recursos gerados pelos respectivos Órgãos que compõem a Administração Indireta do Município, conforme legislação específica de criação de cada entidade; |
| 5 | TRANSFERÊNCIAS E CONVÊNIOS FEDERAIS - VINCULADOS | Recursos originários de transferências federais em virtude de assinatura de convênios ou legislações específicas, cuja destinação encontra-se vinculada aos seus objetos; Demais recursos transferidos pela União que não integram as bases de cálculo para fins de aplicação mínima em Manutenção e Desenvolvimento do Ensino (MDE) e em Ações e Serviços Públicos em Saúde (ASPS); |
| 6 | OUTRAS FONTES DE RECURSOS | Recursos não enquadrados em especificações próprias; PARA UTILIZAÇÃO QUANDO NÃO SE  CONHECE A ORIGEM DO RECURSO, OU UM RECURSO RECEBIDO DE OUTRO MUNICIPIO - NÃO UTILIZAR DE FORMA INDISCRIMINADA |
| 7 | OPERAÇÕES DE CRÉDITO | Recursos originários de operações de crédito internas ou externas; |
| 8 | EMENDAS PARLAMENTARES INDIVIDUAIS - LEGISLATIVO MUNICIPAL | Recursos destinados ao atendimento às emendas parlamentares individuais por força da Emenda Constitucional nº 86, de 17 de março de 2015. |
| 91 | TESOURO - Exercícios Anteriores | Recursos próprios gerados pelo Município, ou decorrentes de Cota-Parte Constitucional; Utilizada apenas para controle das disponibilidades financeiras advindas do exercício anterior. |
| 92 | TRANSFERÊNCIAS E CONVÊNIOS ESTADUAIS - VINCULADOS - Exercícios Anteriores | Recursos originários de transferências estaduais em virtude de assinatura de convênios ou legislações específicas, cuja destinação encontra-se vinculada aos seus objetos; Utilizada apenas para controle das disponibilidades financeiras advindas do exercício anterior. |
| 93 | RECURSOS PRÓPRIOS DE FUNDOS ESPECIAIS DE DESPESA - VINCULADOS - Exercícios Anteriores | Recursos gerados pelos Fundos Especiais de Despesa ou a eles pertencentes, com destinação vinculada conforme legislação específica de criação de cada Fundo; |
| 94 | RECURSOS PRÓPRIOS DA ADMINISTRAÇÃO INDIRETA - Exercícios Anteriores | Recursos gerados pelos respectivos Órgãos que compõem a Administração Indireta do Município, conforme legislação específica de criação de cada entidade; Utilizada apenas para controle das disponibilidades financeiras advindas do exercício anterior. |
| 95 | TRANSFERÊNCIAS E CONVÊNIOS FEDERAIS - VINCULADOS - Exercícios Anteriores | Recursos originários de transferências federais em virtude de assinatura de convênios ou legislações específicas, cuja destinação encontra-se vinculada aos seus objetos; Utilizada apenas para controle das disponibilidades financeiras advindas do exercício anterior. |
| 96 | OUTRAS FONTES DE RECURSOS - Exercícios Anteriores | Recursos não enquadrados em especificações próprias; |
| 97 | OPERAÇÕES DE CRÉDITO - Exercícios Anteriores | Recursos originários de operações de crédito internas ou externas; Utilizada apenas para controle das disponibilidades financeiras advindas do exercício anterior. |
| 98 | EMENDAS PARLAMENTARES INDIVIDUAIS - Exercícios Anteriores | Recursos destinados ao atendimento às emendas parlamentares individuais por força da Emenda Constitucional nº 86, de 17 de março de 2015, do exercício anterior. |
|  |  |  |

## Domínio AUDESP: Índice Econômico

| Código | Descrição |
|--------|-----------|
| 1 | Capital Social Mínimo |
| 2 | Endividamento a Curto Prazo |
| 3 | Endividamento Total |
| 4 | Liquidez Corrente |
| 5 | Liquidez Geral |
| 6 | Liquidez Imediata |
| 7 | Liquidez Seca |
| 8 | Outro |
|  |  |

## Domínio PNCP: Situação do Item da Contratação

| Código | Descrição |
|--------|-----------|
| 1 | Em Andamento: Item com disputa/seleção do fornecedor/arrematante não finalizada. |
| 2 | Homologado: Item com resultado (fornecedor/arrematante informado) |
| 3 | Anulado/Revogado/Cancelado: Item cancelado conforme justificativa |
| 4 | Deserto: Item sem resultado (sem fornecedores/arrematantes interessados) |
| 5 | Fracassado: Item sem resultado (fornecedores/arrematantes desclassificados ou inabilitados) |
|  |  |

## Domínio AUDESP: Orçamento ou Proposta

| Código | Descrição |
|--------|-----------|
| 0 | Não |
| 1 | Sim - Global (Total do Lote) |
| 2 | Sim - Unitário |
| 3 | Sim - Desconto sobre tabela de Referência |
|  |  |

## Domínio AUDESP: Declaração ME EPP

| Código | Descrição |
|--------|-----------|
| 1 | Sim, ME. |
| 2 | Sim, EPP. |
| 3 | Não |
|  |  |

## Domínio AUDESP: Resultado Habilitação

| Código | Descrição |
|--------|-----------|
| 1 | Classificado Vencedor |
| 2 | Classificado |
| 3 | Habilitado |
| 4 | Desclassificado |
| 5 | Desistiu/Não compareceu |
| 6 | Proposta não Analisada |
| 7 | Inabilitado |
|  |  |

## Domínio PNCP: Tipo de Contrato

| Código | Descrição |
|--------|-----------|
| 1 | Contrato (termo inicial): Acordo formal recíproco de vontades firmado entre as partes |
| 2 | Comodato: Contrato de concessão de uso gratuito de bem móvel ou imóvel |
| 3 | Arrendamento: Contrato de cessão de um bem por um determinado período mediante pagamento |
| 4 | Concessão: Contrato firmado com empresa privada para execução de serviço público sendo remunerada por tarifa |
| 5 | Termo de Adesão: Contrato em que uma das partes estipula todas as cláusulas sem a outra parte poder modificá-las |
| 7 | Empenho: É uma promessa de pagamento por parte do Estado para um fim específico |
| 8 | Outros: Outros tipos de contratos que não os listados |
| 12 | Carta Contrato: Documento que formaliza e ratifica acordo entre duas ou mais partes nas hipóteses em que a lei dispensa a celebração de um contrato |
|  |  |

## Domínio PNCP: Categoria do Processo

| Código | Descrição |
|--------|-----------|
| 1 | Cessão |
| 2 | Compras |
| 3 | Informática (TIC) |
| 4 | Internacional |
| 5 | Locação Imóveis |
| 6 | Mão de Obra |
| 7 | Obras |
| 8 | Serviços |
| 9 | Serviços de Engenharia |
| 10 | Serviços de Saúde |
| 11 | Alienação de bens móveis/imóveis |
|  |  |

## Domínio AUDESP: Situação do Contrato

| Código | Descrição |
|--------|-----------|
| 1 | Em execução |
| 2 | Em execução (Atrasado) |
| 3 | Suspenso (paralisado) |
| 4 | Encerrado - Cumprimento Integral |
| 5 | Encerrado - Rescisão com imposição de sanção |
| 6 | Encerrado - Rescisão sem imposição de sanção |
| 7 | Encerrado - Anulado |
|  |  |

## Domínio AUDESP: Objeto do contrato

| Código Categoria do Processo | Categoria do Processo | Código Objeto do Contrato | Objeto do Contrato |
|------------------------------|-----------------------|---------------------------|--------------------|
| 1 | Cessão | 1 | Permissão |
| 1 | Cessão | 2 | Concessão de serviço público |
| 2 | Compras | 3 | Equipamentos e materiais permanentes |
| 2 | Compras | 4 | Material de expediente |
| 2 | Compras | 5 | Medicamentos |
| 2 | Compras | 6 | Material hospitalar, ambulatorial ou odontológico |
| 2 | Compras | 7 | Material escolar |
| 2 | Compras | 8 | Uniforme escolar |
| 2 | Compras | 9 | Gêneros alimentícios |
| 2 | Compras | 10 | Combustíveis e lubrificantes |
| 2 | Compras | 11 | Outros materias de consumo |
| 3 | Informática (TIC) | 12 | Compras de TIC |
| 3 | Informática (TIC) | 13 | Serviços de TIC |
| 3 | Informática (TIC) | 14 | SIAFIC |
| 4 | Internacional | 15 | Internacional |
| 5 | Locação Imóveis | 16 | Locação de imóveis |
| 6 | Mão de Obra | 17 | Locação de mão de obra |
| 7 ou 9 | Obras e Serviços de Engenharia | 18 | Implantação de aterro sanitário |
| 7 ou 9 | Obras e Serviços de Engenharia | 19 | Outras obras e serviços de engenharia |
| 8 | Serviços | 20 | Coleta de Lixo |
| 8 | Serviços | 21 | Limpeza urbana/varrição |
| 8 | Serviços | 22 | Transporte escolar |
| 8 | Serviços | 23 | Publicidade/Propaganda |
| 8 | Serviços | 24 | Passagens aéreas e outras despesas de locomoção |
| 8 | Serviços | 25 | Serviços de consultoria |
| 8 | Serviços | 26 | Operações de crédito (exceto ARO) |
| 8 | Serviços | 27 | Outras prestações de serviço |
| 10 | Serviços de saúde | 28 | Serviços de saúde |
| 11 | Alienação de bens móveis/imóveis | 29 | Alienação de bens móveis/imóveis |
|  |  |  |  |

## Domínio AUDESP: Tipo de Obra

| Código | Descrição |
|--------|-----------|
| 1 | Assessorias ou consultorias técnicas |
| 2 | Auditoria de Obras e Serviços de Engenharia |
| 3 | Conserto, instalação ou manutenção: elevadores e escadas rolantes |
| 4 | Conserto, instalação ou manutenção: instalações elétricas, de iluminação, hidrossanitárias, de águas pluviais, de sonorização ambiente, de comunicação e dados |
| 5 | Conserto, instalação ou manutenção: paisagismo |
| 6 | Conserto, instalação ou manutenção: sinalização horizontal e vertical de vias públicas ou rodovias |
| 7 | Conserto, instalação ou manutenção: sistemas de alarmes em edificações |
| 8 | Conserto, instalação ou manutenção: sistemas de climatização e ar condicionado |
| 9 | Conserto, instalação ou manutenção: sistemas de combate a incêndio |
| 10 | Conserto, instalação ou manutenção: sistemas de controle de acesso ou circuito fechado de televisão |
| 11 | Conserto, instalação ou manutenção: sistemas de proteção contra descargas atmosféricas |
| 12 | Conserto, instalação ou manutenção: sistemas de supervisão e automação predial |
| 13 | Conserto, instalação ou manutenção: sistemas de telefonia e comunicação de dados |
| 14 | Conserto, instalação ou manutenção: sistemas de ventilação e exaustão |
| 15 | Conservação, reparação ou manutenção: adutoras, estações de tratamento e redes de distribuição de água |
| 16 | Conservação, reparação ou manutenção: barragens |
| 17 | Conservação, reparação ou manutenção: edificações |
| 18 | Conservação, reparação ou manutenção: obras de saneamento, drenagem e irrigação |
| 19 | Conservação, reparação ou manutenção: pontes e viadutos |
| 20 | Conservação, reparação ou manutenção:  rodovias |
| 21 | Conservação, reparação ou manutenção:  sistemas de tratamento de resíduos sólidos, incluindo aterros sanitários e usinas de compostagem |
| 22 | Conservação, reparação ou manutenção: trilhos e veículos sobre trilhos |
| 23 | Conservação, reparação ou manutenção: túneis |
| 24 | Conservação, reparação ou manutenção: vias públicas |
| 25 | Construção, reforma ou ampliação: adutoras, estações de tratamento e redes de distribuição de água |
| 26 | Construção, reforma ou ampliação:  barragens |
| 27 | Construção, reforma ou ampliação:  edificações |
| 28 | Construção, reforma ou ampliação:  obras de saneamento, drenagem e irrigação |
| 29 | Construção, reforma ou ampliação:  pontes e viadutos |
| 30 | Construção, reforma ou ampliação:  rodovias |
| 31 | Construção, reforma ou ampliação:  sistemas de tratamento de resíduos sólidos, incluindo aterros sanitários e usinas de compostagem |
| 32 | Construção, reforma ou ampliação:  trilhos e veículos sobre trilhos |
| 33 | Construção, reforma ou ampliação:  túneis |
| 34 | Construção, reforma ou ampliação:  vias públicas |
| 35 | Elaboração de Projeto Básico ou Projeto Executivo |
| 36 | Ensaios tecnológicos |
| 37 | Estudos de Impacto Ambiental |
| 38 | Estudos de Viabilidade Técnica e Econômica |
| 39 | Levantamento aerofotogramétrico |
| 40 | Levantamentos topográficos, batimétricos e geodésicos |
| 41 | Perícias e avaliações |
| 42 | Sondagens ou outros procedimentos de investigação geotécnica |
| 43 | Outros |
|  |  |

## Domínio AUDESP: Regime de execução

| Código | Descrição |
|--------|-----------|
| 1 | empreitada por preço unitário |
| 2 | empreitada por preço global |
| 3 | empreitada integral |
| 4 | contratação por tarefa |
| 5 | contratação integrada |
| 6 | contratação semi-integrada |
| 7 | execução direta |
| 8 | fornecimento e prestação de serviço associado |
| 9 | Concessão pública com obra de engenharia |
| 10 | Não se aplica |
|  |  |

## Domínio PNCP: Tipo de Termo de Contrato

| Código | Descrição | Observação |
|--------|-----------|------------|
| 2 | Termo Aditivo: Atualiza o contrato como um todo, podendo prorrogar, reajustar, acrescer, suprimir, alterar cláusulas e reajustar. | Na Fase IV - AUDESP, devem ser informado apenas os Termos Aditivos |
