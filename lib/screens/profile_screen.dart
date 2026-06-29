import 'package:flutter/material.dart';
import '../viewmodels/profile_view_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // 🚀 뷰모델 생성 및 생명주기 결합
  final ProfileViewModel _viewModel = ProfileViewModel();

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('내 정보 설정')),
      // 🚀 단방향 데이터 바인딩: StreamBuilder 대신 ListenableBuilder 사용
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final user = _viewModel.userProfile;

          // 뷰모델이 DB에서 아직 데이터를 가져오지 못했다면 로딩 창 렌더링
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.blue[50],
                    child: Image.network(user.profileUrl),
                  ),
                ),
                const SizedBox(height: 32),
                
                // 계정 이메일 (읽기 전용)
                TextField(
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: '계정 이메일',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: const OutlineInputBorder(),
                  ),
                  controller: TextEditingController(text: user.email),
                ),
                const SizedBox(height: 16),

                // 🚀 이름 수정 필드 (뷰모델의 컨트롤러 바인딩)
                TextField(
                  controller: _viewModel.nameController,
                  decoration: const InputDecoration(
                    labelText: '성함',
                    hintText: '수정할 이름을 입력하세요',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // 저장 버튼
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _viewModel.isSaving 
                      ? null // 저장 중일 때는 버튼 비활성화 (다중 클릭 방어)
                      : () {
                          FocusScope.of(context).unfocus(); // 키보드 내리기 (UI 역할)
                          
                          // 🚀 비즈니스 로직은 뷰모델에 위임
                          _viewModel.saveName(
                            onSuccess: () {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('프로필이 성공적으로 저장되었습니다.')),
                                );
                              }
                            }
                          );
                        },
                    icon: _viewModel.isSaving 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save),
                    label: Text(_viewModel.isSaving ? '저장 중...' : '저장'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // 로그아웃 버튼
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () => _viewModel.signOut(), // 뷰모델로 위임
                    icon: const Icon(Icons.logout),
                    label: const Text('로그아웃'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}