import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:app/features/friends/models/friend_model.dart';
import 'package:app/features/friends/services/friends_storage_service.dart';
import 'package:app/shared/services/student_data_service.dart';
import 'package:app/theme/theme.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only add up to 10 friends.')),
      );
      return;
    }

    final rollNoController = TextEditingController();
    final nameTagController = TextEditingController();
    bool isSearching = false;

    showCupertinoDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return CupertinoAlertDialog(
              title: const Text('Add Friend'),
              content: Column(
                children: [
                  const SizedBox(height: 16),
                  CupertinoTextField(
                    controller: rollNoController,
                    placeholder: 'Roll Number (e.g., 2405001)',
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
                  ),
                  const SizedBox(height: 12),
                  CupertinoTextField(
                    controller: nameTagController,
                    placeholder: 'Name Tag (e.g., John)',
                    style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
                  ),
                  if (isSearching)
                    const Padding(
                      padding: EdgeInsets.only(top: 16.0),
                      child: CupertinoActivityIndicator(),
                    ),
                ],
              ),
              actions: [
                CupertinoDialogAction(
                  isDestructiveAction: true,
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: isSearching
                      ? null
                      : () async {
                          final rollNo = rollNoController.text.trim();
                          final nameTag = nameTagController.text.trim();
                          
                          if (rollNo.isEmpty || nameTag.isEmpty) {
                            return;
                          }

                          setStateDialog(() => isSearching = true);

                          final result = await StudentDataService.lookupRollNo(rollNo);
                          
                          if (!mounted) return;

                          if (result['success'] == true && result['data'] != null) {
                            final data = result['data'];
                            
                            List<String> friendElectives = [];
                            if (data['electives'] is List) {
                              friendElectives = List<String>.from((data['electives'] as List).map((e) => e.toString()));
                            }

                            final friend = FriendModel(
                              rollNo: data['rollNo'] ?? rollNo,
                              nameTag: nameTag,
                              semester: data['semester'] ?? '',
                              section: data['section'] ?? '',
                              electives: friendElectives,
                            );

                            debugPrint('Added Friend: ${friend.nameTag} (${friend.rollNo}) with electives: $friendElectives');

                            final added = await FriendsStorageService.addFriend(friend);
                            
                            if (!context.mounted) return;

                            if (added) {
                              Navigator.pop(context);
                              _loadFriends();
                            } else {
                              setStateDialog(() => isSearching = false);
                              _showErrorDialog(context, 'Could not add friend. They might already exist.');
                            }
                          } else {
                            if (!context.mounted) return;
                            setStateDialog(() => isSearching = false);
                            _showErrorDialog(context, result['message'] ?? 'Roll number not found');
                          }
                        },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
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
    return CupertinoPageScaffold(
      backgroundColor: UserColors.background,
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: Colors.transparent,
        border: null,
        middle: Text(
          'Friend Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      child: SafeArea(
        child: Material(
          type: MaterialType.transparency,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Your Friends',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _showAddFriendDialog,
                      child: Row(
                        children: const [
                          Icon(CupertinoIcons.add_circled, color: AuthPalette.teal),
                          SizedBox(width: 4),
                          Text('Add Friend', style: TextStyle(color: AuthPalette.teal, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CupertinoActivityIndicator())
                      : _friends.isEmpty
                          ? Center(
                              child: Text(
                                'No friends added.\nTap "Add Friend" to add by Roll Number.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _friends.length,
                              itemBuilder: (context, index) {
                                final friend = _friends[index];
                                return Padding(
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
                                      trailing: IconButton(
                                        icon: const Icon(CupertinoIcons.trash, color: Colors.redAccent, size: 20),
                                        onPressed: () => _confirmDelete(friend),
                                      ),
                                    ),
                                  ),
                                );
                              },
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
