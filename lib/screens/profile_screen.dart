import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/profile_cards/profile_card.dart';
import '../theme/theme_provider.dart';
import '../widgets/navigation/profile_app_bar.dart';
import '../config.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String userFirstName = '';
  String userLastName = '';
  String userEmail = '';
  String userName = '';
  String userRole = 'student';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userFirstName = prefs.getString('userFirstName') ?? '';
      userLastName = prefs.getString('userLastName') ?? '';
      userEmail = prefs.getString('userEmail') ?? '';
      userName = prefs.getString('userName') ?? '';
      userRole = prefs.getString('userRole') ?? 'student';
    });
  }

  Future<void> _fetchUserDataFromBackend() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please login again')),
          );
        }
        return;
      }

      final url = Uri.parse('${Config.BASE_URL}/api/users/me');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timed out');
        },
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);

        await prefs.setString('userFirstName', userData['firstName']);
        await prefs.setString('userLastName', userData['lastName']);
        await prefs.setString('userName', userData['username']);
        await prefs.setString('userEmail', userData['email']);
        await prefs.setString('userRole', userData['role']);

        setState(() {
          userFirstName = userData['firstName'];
          userLastName = userData['lastName'];
          userName = userData['username'];
          userEmail = userData['email'];
          userRole = userData['role'];
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              duration: Duration(seconds: 1),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else if (response.statusCode == 401) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session expired. Please login again'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to refresh: ${response.statusCode}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to refresh. Please try again'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRefresh() async {
    await _fetchUserDataFromBackend();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: ProfileAppBar(themeProvider: themeProvider, username: userName),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: CupertinoColors.activeBlue,
        child: SafeArea(
          child: Stack(
            children: [
              ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 16),
                  ProfileCard(
                    fullName: '$userFirstName $userLastName',
                    email: userEmail,
                    role: userRole,
                    backgroundColor: isDark ? Colors.grey[900]! : Colors.grey[200]!,
                    textColor: isDark ? Colors.white : Colors.black87,
                    iconColor: CupertinoColors.activeBlue,
                  ),
                ],
              ),
              if (_isLoading)
                Container(
                  color: Colors.black26,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}