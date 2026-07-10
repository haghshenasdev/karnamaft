import 'package:flutter/material.dart';

class PasswordCard extends StatefulWidget {
  final Future<void> Function(String currentPassword, String newPassword)?
  onChangePassword;

  const PasswordCard({super.key, this.onChangePassword});

  @override
  State<PasswordCard> createState() => _PasswordCardState();
}

class _PasswordCardState extends State<PasswordCard> {
  final _formKey = GlobalKey<FormState>();

  final _currentController = TextEditingController();

  final _newController = TextEditingController();

  final _confirmController = TextEditingController();

  bool _currentVisible = false;

  bool _newVisible = false;

  bool _confirmVisible = false;

  bool _loading = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      if (widget.onChangePassword != null) {
        await widget.onChangePassword!(
          _currentController.text,
          _newController.text,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("رمز عبور با موفقیت تغییر کرد.")),
      );

      _currentController.clear();
      _newController.clear();
      _confirmController.clear();
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ExpansionTile(
        initiallyExpanded: false,
        leading: const Icon(Icons.lock_outline),
        title: Text(
          "امنیت حساب",
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text("تغییر رمز عبور"),
        childrenPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                //-----------------------------------
                // Current Password
                //-----------------------------------
                TextFormField(
                  controller: _currentController,
                  obscureText: !_currentVisible,
                  decoration: InputDecoration(
                    labelText: "رمز عبور فعلی",
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _currentVisible = !_currentVisible;
                        });
                      },
                      icon: Icon(
                        _currentVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "رمز عبور فعلی را وارد کنید.";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                //-----------------------------------
                // New Password
                //-----------------------------------
                TextFormField(
                  controller: _newController,
                  obscureText: !_newVisible,
                  decoration: InputDecoration(
                    labelText: "رمز عبور جدید",
                    prefixIcon: const Icon(Icons.lock_reset),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _newVisible = !_newVisible;
                        });
                      },
                      icon: Icon(
                        _newVisible ? Icons.visibility_off : Icons.visibility,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "رمز عبور جدید را وارد کنید.";
                    }

                    if (value.length < 6) {
                      return "رمز عبور باید حداقل ۶ کاراکتر باشد.";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                //-----------------------------------
                // Confirm Password
                //-----------------------------------
                TextFormField(
                  controller: _confirmController,
                  obscureText: !_confirmVisible,
                  decoration: InputDecoration(
                    labelText: "تکرار رمز عبور",
                    prefixIcon: const Icon(Icons.password),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _confirmVisible = !_confirmVisible;
                        });
                      },
                      icon: Icon(
                        _confirmVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "تکرار رمز عبور را وارد کنید.";
                    }

                    if (value != _newController.text) {
                      return "تکرار رمز عبور صحیح نیست.";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 24),

                //-----------------------------------
                // Button
                //-----------------------------------
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _loading ? null : _submit,
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.lock_reset),
                    label: Text(
                      _loading ? "در حال تغییر..." : "تغییر رمز عبور",
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
