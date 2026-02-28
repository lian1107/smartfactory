class Validators {
  Validators._();

  static String? required(String? value, [String? label]) {
    if (value == null || value.trim().isEmpty) {
      return '${label ?? '此项'}不能为空';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '请输入邮箱地址';
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return '请输入有效的邮箱地址';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return '请输入密码';
    }
    if (value.length < 6) {
      return '密码至少需要 6 位字符';
    }
    return null;
  }

  static String? minLength(String? value, int min, [String? label]) {
    if (value == null || value.trim().length < min) {
      return '${label ?? '此项'}至少需要 $min 个字符';
    }
    return null;
  }

  static String? maxLength(String? value, int max, [String? label]) {
    if (value != null && value.trim().length > max) {
      return '${label ?? '此项'}不能超过 $max 个字符';
    }
    return null;
  }

  static String? productCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '请输入产品编号';
    }
    final codeRegex = RegExp(r'^[A-Za-z0-9\-_\.]+$');
    if (!codeRegex.hasMatch(value.trim())) {
      return '产品编号只能包含字母、数字、连字符和下划线';
    }
    return null;
  }

  static String? positiveNumber(String? value, [String? label]) {
    if (value == null || value.trim().isEmpty) return null;
    final num = double.tryParse(value.trim());
    if (num == null) return '${label ?? '此项'}必须是有效数字';
    if (num <= 0) return '${label ?? '此项'}必须大于 0';
    return null;
  }

  /// Combine multiple validators, returning first error found
  static String? Function(String?) combine(
    List<String? Function(String?)> validators,
  ) {
    return (value) {
      for (final v in validators) {
        final err = v(value);
        if (err != null) return err;
      }
      return null;
    };
  }
}
