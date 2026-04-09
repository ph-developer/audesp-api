# Edital
- Planejar a importação dos itens via planilha (csv). Entendo que seria viável utilizar o mesmo arquivo que é usado na licitação (Planilha de Itens), adaptando para o usuário não precisar preencher mais uma planilha, uma vez que o Serviço de Licitações lança o edital e a licitação ao mesmo tempo na audesp (apenas após finalização do certame). Para tal, montar um PRD (Product Requirements Document). em caso de necessidade de decisões arquiteturais, deve ser colocado no arquivo os questionamentos e/ou sugestões.

# Licitação
- O código do edital deve vir do edital vinculado, não ser digitável
- Corrigir valores da exigência de amostra: 1 - Sim, para todos os licitantes; 2 - Sim, somente do vencedor do certame; 3 - Não
- Corrigir valores da exigência de visita técnica: 1 - Sim; 2 - Não; 3 - O processo não se refere à obra nem a serviço de engenharia
- O Campo "Valor" que fica na inclusão de item, refere-se ao valor médio dos orçamentos da estimativa e não ao valor estimado em si, é só um ajuste de nomes

# Ata
- Mostrar código do município e entidade (referência: Formulário da Licitação)
- O código do Edital deve vir do Edital vinculado, e não ser digitável
- Retirar os indicadores de limite de tamanho dos campos

# Ajuste
- Mostrar código do município e entidade (referência: Formulário da Licitação)
- O código do Edital deve vir do Edital vinculado, e não ser digitável
- O código da Ata deve vir da Ata vinculada, e não ser digitável
- Retirar os indicadores de limite de tamanho dos campos
- O número do processo não é opcional
- O campo de Receita ou Despesa deve ser melhorado, talvez com uma switch
- Classificação de despesa não é obrigatório no caso de receita (confirmar no schema)
- Categoria do processo deve ser pesquisável (da mesma forma que é feito no Edital > Amparo Legal)
- Tipo do Objeto deve ser pesquisável (da mesma forma que é feito no Edital > Amparo Legal)