import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:app/features/friends/models/friend_model.dart';
import 'package:app/features/friends/services/friends_storage_service.dart';
import 'package:app/theme/theme.dart';
import 'package:app/shared/widgets/dialogs/custom_glass_dialog.dart';
import 'package:app/features/friends/widgets/add_friend_dialog_flow.dart';
import 'package:app/shared/widgets/dialogs/toast_manager.dart';

class FriendsSettingsScreen extends StatefulWidget {
  const FriendsSettingsScreen({super.key});

  @override
  State<FriendsSettingsScreen> createState() => _FriendsSettingsScreenState();
}

class _FriendsSettingsScreenState extends State<FriendsSettingsScreen> {
  List<FriendModel> _friends = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    final friends = await FriendsStorageService.getFriends();
    setState(() {
      _friends = friends;
      _isLoading = false;
    });
  }

  void _showAddFriendDialog() {
    if (_friends.length >= 10) {
      EduMateToast.showCompact(
        context,
        message: 'You can only add up to 10 friends.',
        isSuccess: false,
      );
      return;
    }

    showGlassmorphicDialog(
      context: context,
      child: AddFriendDialogFlow(
        onComplete: _loadFriends,
      ),
    );
  }

  void _confirmDelete(FriendModel friend) {
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Remove Friend'),
          content: Text('Are you sure you want to remove ${friend.nameTag}?'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () async {
                Navigator.pop(context);
                await FriendsStorageService.removeFriend(friend.rollNo);
                _loadFriends();
              },
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editFriendName(FriendModel friend) async {
    final TextEditingController controller = TextEditingController(text: friend.nameTag);
    bool isSaving = false;

    final newName = await showGlassmorphicDialog<String>(
      context: context,
      child: StatefulBuilder(
        builder: (context, setDialogState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Edit Friend Name',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: controller,
                placeholder: 'Name Tag (e.g., John)',
                placeholderStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                style: const TextStyle(color: Colors.white),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Center(
                          child: Text('Cancel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        if (controller.text.trim().isEmpty) return;
                        setDialogState(() => isSaving = true);
                        Navigator.pop(context, controller.text.trim());
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AuthPalette.coral,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: isSaving
                              ? const CupertinoActivityIndicator(color: Colors.white)
                              : const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != friend.nameTag) {
      final index = _friends.indexOf(friend);
      if (index != -1) {
        setState(() {
          _friends[index] = FriendModel(
            rollNo: friend.rollNo,
            nameTag: newName,
            semester: friend.semester,
            section: friend.section,
            electives: friend.electives,
          );
        });
        await FriendsStorageService.saveFriends(_friends);
      }
    }
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF141110),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Material(
          type: MaterialType.transparency,
          child: Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 12.0,
              bottom: 16.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    const Text(
                      'Manage Friends',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontFamily: 'Salena',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _showAddFriendDialog,
                        child: const Icon(CupertinoIcons.add_circled, color: AuthPalette.teal, size: 28),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: _isLoading
                      ? const Center(child: CupertinoActivityIndicator())
                      : _friends.isEmpty
                          ? Center(
                              child: Text(
                                'No friends added.\nTap "+" to add by Roll Number.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                              ),
                            )
                          : Theme(
                              data: Theme.of(context).copyWith(
                                canvasColor: Colors.transparent,
                              ),
                              child: ReorderableListView.builder(
                                itemCount: _friends.length,
                                proxyDecorator: (child, index, animation) {
                                  return Material(
                                    type: MaterialType.transparency,
                                    child: child,
                                  );
                                },
                                onReorder: (oldIndex, newIndex) async {
                                  setState(() {
                                    if (newIndex > oldIndex) {
                                      newIndex -= 1;
                                    }
                                    final friend = _friends.removeAt(oldIndex);
                                    _friends.insert(newIndex, friend);
                                  });
                                  await FriendsStorageService.saveFriends(_friends);
                                },
                                itemBuilder: (context, index) {
                                  final friend = _friends[index];
                                  return Padding(
                                    key: ValueKey(friend.rollNo),
                                    padding: const EdgeInsets.only(bottom: 12.0),
                                    child: _buildGlassCard(
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: AuthPalette.teal,
                                          child: Text(
                                            friend.nameTag.substring(0, 1).toUpperCase(),
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        title: Text(
                                          friend.nameTag,
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Text(
                                          '${friend.rollNo} • ${friend.section} (${friend.semester})',
                                          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(CupertinoIcons.pencil, color: Color(0xFF10B981), size: 20),
                                              onPressed: () => _editFriendName(friend),
                                            ),
                                            IconButton(
                                              icon: const Icon(CupertinoIcons.trash, color: Colors.redAccent, size: 20),
                                              onPressed: () => _confirmDelete(friend),
                                            ),
                                            ReorderableDragStartListener(
                                              index: index,
                                              child: const Icon(Icons.drag_handle, color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
