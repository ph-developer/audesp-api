// Domain constants for the Licitação module (Fase 5).
// Source: AUDESP API licitacao-schema-v4.json

/// Recurso BID / tri-state genérico (1=Sim, 2=Não, 3=Não se aplica).
const kTriState = <int, String>{
  1: '1 – Sim',
  2: '2 – Não',
  3: '3 – Não se aplica',
};

/// `recursoBID` — indica se há recursos do BID envolvidos.
const kRecursoBID = <int, String>{
  1: '1 – Sim',
  2: '2 – Não',
  3: '3 – Não se Aplica',
};

/// `exigenciaAmostra` — Domínio AUDESP.
const kExigenciaAmostra = <int, String>{
  1: '1 – Sim, para todos os licitantes',
  2: '2 – Sim, somente do vencedor do certame',
  3: '3 – Não',
};

/// `exigenciaVisitaTecnica` — Domínio AUDESP.
const kExigenciaVisitaTecnica = <int, String>{
  1: '1 – Sim',
  2: '2 – Não',
  3: '3 – O processo não se refere à obra nem a serviço de engenharia',
};

/// `tipoNatureza` — Domínio AUDESP: Tipo de Natureza.
const kTipoNatureza = <int, String>{
  1: '1 – Normal',
  2: '2 – Concessão/permissão de uso (Lei 14.133/2024)',
  3: '3 – Concessão de serviço público ordinária (Lei 8.987/1995)',
  4: '4 – Concessão Pública - PPP Patrocinada (Lei 11.079/2004)',
  5: '5 – Concessão Pública - PPP Administrativa (Lei 11.079/2004)',
  6: '6 – Permissão de serviço público (Lei 8.987/1995)',
  7: '7 – Credenciamento (Lei 14.133/2021)',
  8: '8 – Registro de Preços (Lei 14.133/2021)',
};

/// `fonteRecursosContratacao` — Domínio AUDESP: Fonte de Recursos (multi-select).
const kFonteRecurso = <int, String>{
  1: '1 – Tesouro',
  2: '2 – Transferências e Convênios Estaduais - Vinculados',
  3: '3 – Recursos Próprios de Fundos Especiais de Despesa - Vinculados',
  4: '4 – Recursos Próprios da Administração Indireta',
  5: '5 – Transferências e Convênios Federais - Vinculados',
  6: '6 – Outras Fontes de Recursos',
  7: '7 – Operações de Crédito',
  8: '8 – Emendas Parlamentares Individuais - Legislativo Municipal',
  91: '91 – Tesouro - Exercícios Anteriores',
  92: '92 – Transferências e Convênios Estaduais - Vinculados - Exercícios Anteriores',
  93: '93 – Recursos Próprios de Fundos Especiais de Despesa - Vinculados - Exercícios Anteriores',
  94: '94 – Recursos Próprios da Administração Indireta - Exercícios Anteriores',
  95: '95 – Transferências e Convênios Federais - Vinculados - Exercícios Anteriores',
  96: '96 – Outras Fontes de Recursos - Exercícios Anteriores',
  97: '97 – Operações de Crédito - Exercícios Anteriores',
  98: '98 – Emendas Parlamentares Individuais - Exercícios Anteriores',
};

/// `tipoOrcamento` — Domínio AUDESP: Orçamento ou Proposta.
const kTipoOrcamento = <int, String>{
  0: '0 – Não',
  1: '1 – Sim - Global (Total do Lote)',
  2: '2 – Sim - Unitário',
  3: '3 – Sim - Desconto sobre tabela de Referência',
};

/// `situacaoCompraItemId` — Domínio PNCP: Situação do Item da Contratação.
const kSituacaoCompraItem = <int, String>{
  1: '1 – Em Andamento',
  2: '2 – Homologado',
  3: '3 – Anulado/Revogado/Cancelado',
  4: '4 – Deserto',
  5: '5 – Fracassado',
};

/// `tipoProposta` — Domínio AUDESP: Orçamento ou Proposta (0 não permitido).
const kTipoProposta = <int, String>{
  1: '1 – Sim - Global (Total do Lote)',
  2: '2 – Sim - Unitário',
  3: '3 – Sim - Desconto sobre tabela de Referência',
};

/// `tipoValor` — tipo de valor da proposta (P=Percentual, M=Monetário).
const kTipoValor = <String, String>{
  'M': 'M – Monetário',
  'P': 'P – Percentual',
};

/// `tipoPessoaId` — tipo de pessoa do licitante.
const kTipoPessoa = <String, String>{
  'PJ': 'PJ – Pessoa Jurídica',
  'PF': 'PF – Pessoa Física',
  'PE': 'PE – Pessoa Estrangeira',
};

/// `declaracaoMEouEPP` — Domínio AUDESP: Declaração ME EPP.
const kDeclaracaoMEouEPP = <int, String>{
  1: '1 – Sim, ME',
  2: '2 – Sim, EPP',
  3: '3 – Não',
};

/// `resultadoHabilitacao` — Domínio AUDESP: Resultado Habilitação.
const kResultadoHabilitacao = <int, String>{
  1: '1 – Classificado Vencedor',
  2: '2 – Classificado',
  3: '3 – Habilitado',
  4: '4 – Desclassificado',
  5: '5 – Desistiu/Não compareceu',
  6: '6 – Proposta não Analisada',
  7: '7 – Inabilitado',
};

/// `tipoIndice` — Domínio AUDESP: Índice Econômico.
const kTipoIndice = <int, String>{
  1: '1 – Capital Social Mínimo',
  2: '2 – Endividamento a Curto Prazo',
  3: '3 – Endividamento Total',
  4: '4 – Liquidez Corrente',
  5: '5 – Liquidez Geral',
  6: '6 – Liquidez Imediata',
  7: '7 – Liquidez Seca',
  8: '8 – Outro',
};
