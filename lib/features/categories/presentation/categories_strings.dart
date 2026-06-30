class CategoriesStrings {
  CategoriesStrings._();

  static const tab = 'Categorias';
  static const expense = 'Despesa';
  static const income = 'Receita';

  static const empty = 'Nenhuma categoria ainda';
  static const showArchived = 'Mostrar arquivadas';
  static const archivedTag = 'Arquivada';

  static const newCategory = 'Nova categoria';
  static const renameTitle = 'Renomear categoria';
  static const nameLabel = 'Nome';
  static const create = 'Criar';
  static const save = 'Salvar';
  static const rename = 'Renomear';
  static const delete = 'Excluir';
  static const cancel = 'Cancelar';

  static const deleteConfirmTitle = 'Excluir categoria?';
  static String deleteConfirmBody(String name) =>
      'A categoria "$name" será excluída permanentemente.';

  static const loadError = 'Não foi possível carregar as categorias.';
  static const retry = 'Tentar novamente';

  // Validation / conflicts
  static const nameRequired = 'Informe um nome.';
  static const nameTooLong = 'Máximo de 60 caracteres.';
  static const dupName = 'Já existe uma categoria com esse nome.';
  static const inUse = 'Categoria em uso e não pode ser excluída.';
}
