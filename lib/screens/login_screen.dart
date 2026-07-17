import 'package:flutter/material.dart';
import 'package:flutter_chat_app_ys/const/colors.dart';
import 'package:flutter_chat_app_ys/viewmodels/login_viewmodel.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  LoginViewModel? _viewModel;

  @override
  void initState() {
    _viewModel = LoginViewModel();
    super.initState();
  }

  @override
  void dispose() {
    _viewModel?.dispose(); // 화면이 파괴될 때 뷰모델 내의 컨트롤러들도 동시 해제
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      // 데이터 바인딩: _viewModel의 notifyListeners()가 실행될 때마다 아래 영역만 유기적으로 다시 그려짐
      body: ListenableBuilder(
        listenable: _viewModel!,
        builder: (context, _) {
          return Scaffold(
            appBar: AppBar(
              title: Text(_viewModel!.isSignUp ? '회원가입' : '로그인'),
              elevation: 0,
            ),
            body: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_viewModel!.isSignUp) ...[
                      TextField(
                        controller: _viewModel!.nameController, // 뷰모델의 컨트롤러 바인딩
                        decoration: const InputDecoration(
                          labelText: '실명',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextField(
                      controller: _viewModel!.emailController,
                      decoration: const InputDecoration(
                        labelText: '이메일',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _viewModel!.passwordController,
                      decoration: const InputDecoration(
                        labelText: '비밀번호',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    if (_viewModel!.isSignUp) ...[
                      TextField(
                        controller: _viewModel!.passwordConfirmController,
                        decoration: const InputDecoration(
                          labelText: '비밀번호 재확인',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),
                    ],
                    const SizedBox(height: 8),

                    // 로딩 상태에 따른 버튼 조건부 렌더링
                    SizedBox(
                      height: 50,
                      child: _viewModel!.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: () => _viewModel!.submit(
                                onSuccess: () {
                                  if (!mounted) return;
                                  ('로그인 성공!');
                                },
                                onError: (errorMessage) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(errorMessage)),
                                  );
                                },
                              ),
                              child: Text(
                                _viewModel!.isSignUp ? '가입하기' : '로그인',
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _viewModel!.toggleMode, // 뷰모델로 상태 제어 위임
                      child: Text(
                        _viewModel!.isSignUp
                            ? '이미 계정이 있으신가요? 로그인'
                            : '계정이 없으신가요? 회원가입',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
