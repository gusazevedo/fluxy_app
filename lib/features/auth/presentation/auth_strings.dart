// lib/features/auth/presentation/auth_strings.dart
class AuthStrings {
  AuthStrings._();

  // Shared
  static const genericError = 'Algo deu errado. Tente novamente.';
  static const email = 'E-mail';
  static const password = 'Senha';
  static const invalidEmail = 'Informe um e-mail válido.';
  static const shortPassword = 'A senha deve ter ao menos 8 caracteres.';
  static const longPassword = 'A senha deve ter no máximo 200 caracteres.';
  static const requiredField = 'Campo obrigatório.';
  static const longName = 'Use no máximo 100 caracteres.';
  static const passwordsDontMatch = 'As senhas não coincidem.';

  // Login
  static const loginTitle = 'Bem-vindo de volta';
  static const loginSubtitle = 'Entre para acompanhar suas finanças.';
  static const loginCta = 'Entrar';
  static const forgotPassword = 'Esqueci minha senha';
  static const noAccount = 'Não tem conta?';
  static const signUp = 'Cadastre-se';
  static const invalidCredentials = 'E-mail ou senha inválidos.';

  // Register
  static const registerTitle = 'Criar conta';
  static const registerSubtitle = 'Comece a organizar seu dinheiro hoje.';
  static const firstName = 'Nome';
  static const lastName = 'Sobrenome';
  static const confirmPassword = 'Confirmar senha';
  static const registerCta = 'Cadastrar';
  static const haveAccount = 'Já tem conta?';
  static const signIn = 'Entrar';

  // Verify email
  static const verifyTitle = 'Confirme seu e-mail';
  static String verifySubtitle(String email) =>
      'Digite o código de 6 dígitos que enviamos para $email.';
  static const resendCode = 'Reenviar código';
  static String resendIn(int seconds) => 'Reenviar código em ${seconds}s';
  static const invalidCode = 'Código inválido ou expirado.';
  static const changeEmail = 'Trocar e-mail';

  // Forgot password
  static const forgotTitle = 'Recuperar senha';
  static const forgotSubtitle =
      'Informe seu e-mail e enviaremos um código para redefinir sua senha.';
  static const sendCode = 'Enviar código';
  static const forgotNeutral =
      'Se houver uma conta com esse e-mail, enviamos um código.';
  static const rememberedPassword = 'Lembrou a senha?';
  static const backToLogin = 'Voltar ao login';

  // Reset password
  static const resetTitle = 'Nova senha';
  static const resetSubtitle = 'Crie uma nova senha para sua conta.';
  static const code = 'Código';
  static const newPassword = 'Nova senha';
  static const confirmNewPassword = 'Confirmar nova senha';
  static const minChars = 'Mínimo de 8 caracteres';
  static const savePassword = 'Salvar senha';
  static const passwordResetDone = 'Senha alterada. Faça login.';
}
