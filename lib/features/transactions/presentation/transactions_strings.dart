class TransactionsStrings {
  TransactionsStrings._();

  static const tab = 'Transações';
  static const empty = 'Nenhuma transação ainda';
  static const loadError = 'Não foi possível carregar as transações.';
  static const loadMoreError = 'Não foi possível carregar mais.';

  static const noCategory = '—';

  // Create / edit
  static const newTransaction = 'Nova transação';
  static const editTitle = 'Editar transação';
  static const expense = 'Despesa';
  static const income = 'Receita';
  static const amountLabel = 'Valor';
  static const categoryLabel = 'Categoria';
  static const categoryHint = 'Selecione uma categoria';
  static const dateLabel = 'Data';
  static const descriptionLabel = 'Descrição (opcional)';
  static const create = 'Criar';
  static const save = 'Salvar';
  static const delete = 'Excluir';
  static const cancel = 'Cancelar';

  // Delete
  static const deleteConfirmTitle = 'Excluir transação?';
  static const deleteConfirmBody =
      'Esta transação será excluída permanentemente.';

  // Filters
  static const filterAll = 'Tudo';
  static const filterCategoryAll = 'Todas as categorias';
  static const filterPeriod = 'Período';
  static const filterClearPeriod = 'Limpar período';

  // Validation / conflicts
  static const amountRequired = 'Informe um valor.';
  static const amountInvalid = 'Valor deve ser maior que zero.';
  static const categoryRequired = 'Selecione uma categoria.';
  static const descriptionTooLong = 'Máximo de 280 caracteres.';
  static const categoryArchived = 'A categoria está arquivada.';
  static const categoryKindMismatch =
      'A categoria não corresponde ao tipo da transação.';
  static const notFound = 'Transação não encontrada.';
}
