import 'dart:async';
import 'dart:convert';
import 'dart:collection';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class SapWebViewScraper {
  static final SapWebViewScraper instance = SapWebViewScraper._internal();
  SapWebViewScraper._internal();

  HeadlessInAppWebView? _headlessWebView;
  InAppWebViewController? _controller;
  String? _extractorJs;
  
  final ValueNotifier<bool> isPageLoaded = ValueNotifier(false);
  Completer<String?>? _pendingAttendanceCompleter;

  Future<void> init() async {
    if (_headlessWebView != null && _controller != null) return; // Already initialized

    _extractorJs = await rootBundle.loadString('assets/js/attendance_extractor.js');
    final controllerCompleter = Completer<void>();

    _headlessWebView = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(url: WebUri('https://kiitportal.kiituniversity.net/irj/portal/')),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        domStorageEnabled: true,
        thirdPartyCookiesEnabled: true,
        useHybridComposition: true,
        supportMultipleWindows: false,
        cacheEnabled: false,
        clearCache: true,
      ),
      initialUserScripts: UnmodifiableListView<UserScript>([
        UserScript(
          source: _extractorJs!,
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_END,
          forMainFrameOnly: true,
        ),
      ]),
      onWebViewCreated: (controller) {
        _controller = controller;
        controller.addJavaScriptHandler(handlerName: 'attendanceResult', callback: (args) {
          if (_pendingAttendanceCompleter != null && !_pendingAttendanceCompleter!.isCompleted) {
             _pendingAttendanceCompleter!.complete(args[0]?.toString());
          }
        });
        if (!controllerCompleter.isCompleted) {
          controllerCompleter.complete();
        }
      },
      onLoadStop: (controller, url) {
        isPageLoaded.value = false;
        Future.microtask(() {
          isPageLoaded.value = true;
        });
      },
      onReceivedServerTrustAuthRequest: (controller, challenge) async {
        return ServerTrustAuthResponse(action: ServerTrustAuthResponseAction.PROCEED);
      },
      onReceivedClientCertRequest: (controller, challenge) async {
        return ClientCertResponse(
          action: ClientCertResponseAction.IGNORE,
          certificatePath: '',
        );
      },
    );

    await _headlessWebView?.run();
    await controllerCompleter.future.timeout(const Duration(seconds: 10), onTimeout: () {});
  }

  Future<bool> waitForPageLoad({Duration timeout = const Duration(seconds: 15)}) async {
    if (!isPageLoaded.value) {
      final completer = Completer<void>();
      void listener() {
        if (isPageLoaded.value) {
          isPageLoaded.removeListener(listener);
          if (!completer.isCompleted) completer.complete();
        }
      }
      isPageLoaded.addListener(listener);
      try {
        await completer.future.timeout(timeout);
      } catch (e) {
        isPageLoaded.removeListener(listener);
        return false;
      }
    }
    
    // Additional wait for DOM ready
    final endTime = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(endTime)) {
      try {
        final result = await _controller?.evaluateJavascript(
          source: "document.readyState === 'complete' && document.body !== null",
        );
        if (result == true) {
          await Future.delayed(const Duration(milliseconds: 500));
          return true;
        }
      } catch (e) {}
      await Future.delayed(const Duration(milliseconds: 100));
    }
    return false;
  }

  Future<bool> login(String username, String password) async {
    if (_controller == null) {
      await init();
    }

    // 1. Check if we are ALREADY logged into the portal on the Overview page
    try {
      final currentTitle = await _controller?.evaluateJavascript(source: 'document.title');
      final currentUrl = await _controller?.getUrl();
      if (currentTitle is String &&
          currentTitle.contains('Overview') &&
          currentUrl != null &&
          currentUrl.toString().contains('kiitportal.kiituniversity.net')) {
        print('SAP_DEBUG [Scraper]: Already logged into portal (Overview active). Skipping re-login.');
        return true;
      }
    } catch (e) {
      // Ignore evaluation errors and proceed with normal navigation
    }

    // 2. Navigate to portal home to load the login page
    isPageLoaded.value = false;
    await _controller?.loadUrl(
      urlRequest: URLRequest(
        url: WebUri('https://kiitportal.kiituniversity.net/irj/portal/'),
      ),
    );
    await waitForPageLoad(timeout: const Duration(seconds: 15));

    // 3. Check if we reached Overview directly via an existing active session
    final loadedTitle = await _controller?.evaluateJavascript(source: 'document.title');
    if (loadedTitle is String && loadedTitle.contains('Overview')) {
      print('SAP_DEBUG [Scraper]: Session active, reached Overview directly.');
      return true;
    }

    // 4. Check if #logonuidfield is ready
    bool loginFieldReady = false;
    for (int i = 0; i < 15; i++) {
      final exists = await _controller?.evaluateJavascript(
        source: "document.querySelector('#logonuidfield') !== null",
      );
      if (exists == true) {
        loginFieldReady = true;
        break;
      }
      await Future.delayed(const Duration(milliseconds: 300));
    }

    if (!loginFieldReady) {
      print('SAP_DEBUG [Scraper]: Login field not found and session not active.');
      return false;
    }

    print('SAP_DEBUG [Scraper]: Entering credentials for user $username...');
    isPageLoaded.value = false;
    await _controller?.evaluateJavascript(source: """
      (function() {
        const uid = document.querySelector('#logonuidfield');
        const pass = document.querySelector('#logonpassfield');
        if (uid && pass) {
          uid.value = '$username';
          uid.dispatchEvent(new Event('input', { bubbles: true }));
          pass.value = '$password';
          pass.dispatchEvent(new Event('input', { bubbles: true }));
          const btn = document.querySelector('input[type="submit"][name="uidPasswordLogon"]');
          if (btn) btn.click();
        }
      })();
    """);

    await waitForPageLoad(timeout: const Duration(seconds: 12));

    // Poll for title 'Overview' or error message
    for (int i = 0; i < 20; i++) {
      final title = await _controller?.evaluateJavascript(source: 'document.title');
      if (title is String && title.contains('Overview')) {
        print('SAP_DEBUG [Scraper]: Successfully authenticated and reached Overview page.');
        return true;
      }
      
      final hasError = await _controller?.evaluateJavascript(source: '''
        (function() {
          const errorDiv = document.querySelector('div.urMsgBarErr');
          if (!errorDiv) return false;
          const errorText = errorDiv.querySelector('span.urTxtMsg');
          return errorText && errorText.textContent.trim() === 'User authentication failed';
        })();
      ''');
      if (hasError == true) {
        print('SAP_DEBUG [Scraper]: SAP reported authentication failure for $username.');
        return false;
      }
      
      await Future.delayed(const Duration(milliseconds: 400));
    }

    final currentUrl = await _controller?.getUrl();
    if (currentUrl != null && currentUrl.toString().contains('navigationtarget')) {
      return true;
    }

    return false;
  }

  Future<bool> navigateToAttendance() async {
    try {
      print('SAP_DEBUG [Provider]: Navigating to attendance via portal Navigate event...');

      // This NavigationTarget hash identifies the "Attendance" iview in the
      // portal's role/content configuration (PCD). It is a STATIC content ID,
      // not a session token, and should be the same for every student/login —
      // it was captured from a real HAR of a manual click on the Attendance
      // tile. If KIIT restructures the portal menu this may need updating —
      // see debugDumpNavLinks() fallback below.
      const navigationTarget = 'navurl://d9e561225c8c41ba6c0ab7b41d3a134d';

      final postBody =
          'NavigationTarget=${Uri.encodeComponent(navigationTarget)}'
          '&RelativeNavBase='
          '&PrevNavTarget='
          '&Command=SUSPEND'
          '&SerPropString='
          '&SerKeyString='
          '&SerAttrKeyString='
          '&SerWinIdString='
          '&DebugSet='
          '&Embedded=true'
          '&SessionKeysAvailable=true';

      const navigateUrl =
          'https://kiitportal.kiituniversity.net/irj/servlet/prt/portal/prteventname/'
          'Navigate/prtroot/pcd!3aportal_content!2fevery_user!2fgeneral!2fdefaultDesktop'
          '!2fframeworkPages!2fframeworkpage!2fcom.sap.portal.innerpage?ExecuteLocally=true';

      isPageLoaded.value = false;

      await _controller?.loadUrl(
        urlRequest: URLRequest(
          url: WebUri(navigateUrl),
          method: 'POST',
          body: Uint8List.fromList(utf8.encode(postBody)),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        ),
      );

      // This Navigate leg is cookie-authenticated (regular portal session).
      // No ext-sid handling needed on our side — the response's hidden
      // isolatedWorkAreaForm auto-submits itself via the WebView's own JS,
      // carrying a real, freshly-issued sap-ext-sid to WDPRD.
      final loaded = await waitForPageLoad(timeout: const Duration(seconds: 15));
      if (!loaded) {
        print('SAP_DEBUG [Provider]: Navigate POST did not complete in time');
        return false;
      }
      
      print('SAP_DEBUG [Provider]: Successfully initiated Navigate POST');
      
      // Wait for the inner iframes to finish loading (portal uses ajax/iframes)
      await Future.delayed(const Duration(milliseconds: 2500));

      // Wait for the Web Dynpro root form (sap.client.SsrClient.form) to appear
      bool foundForm = false;
      for (int i = 0; i < 30; i++) {
        final formFound = await _controller?.evaluateJavascript(source: '''
          (function() {
            function searchWin(win) {
              try {
                if (win.document && win.document.forms['sap.client.SsrClient.form']) return true;
                for (let i = 0; i < win.frames.length; i++) {
                  if (searchWin(win.frames[i])) return true;
                }
              } catch(e) {}
              return false;
            }
            return searchWin(window);
          })();
        ''');
        if (formFound == true) {
          foundForm = true;
          break;
        }
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      if (!foundForm) {
        // DEBUG: If not found, dump all frames to find where it is!
        final dump = await _controller?.evaluateJavascript(source: '''
          (function() {
            var out = [];
            function scan(win, path) {
              try {
                var info = path + " -> HTML len: " + (win.document ? win.document.documentElement.innerHTML.length : 0);
                if (win.document && win.document.forms) {
                  var formNames = [];
                  for(var i=0; i<win.document.forms.length; i++) {
                    formNames.push(win.document.forms[i].name || win.document.forms[i].id || 'unnamed');
                  }
                  info += " Forms: " + formNames.join(", ");
                }
                out.push(info);
                for (var i = 0; i < win.frames.length; i++) {
                  scan(win.frames[i], path + ".frames[" + i + "]");
                }
              } catch(e) {
                out.push(path + " -> CORS ERROR: " + e.message);
              }
            }
            scan(window, "window");
            return out.join("\\n");
          })();
        ''');
        print('SAP_DEBUG [Provider]: FRAME DUMP:\\n' + dump.toString());
        print('SAP_DEBUG [Provider]: Could not find sap.client.SsrClient.form.');
        return false;
      }

      print('SAP_DEBUG [Provider]: Found WebDynpro app in frames. Ready for extraction.');
      return true;
    } catch (e) {
      print('SAP_DEBUG [Provider]: Error during Navigate: $e');
      return false;
    }
  }

  Future<void> debugDumpNavLinks() async {
    final dump = await _controller?.evaluateJavascript(source: '''
      (function() {
        var els = document.querySelectorAll('a, span[onclick], div[onclick]');
        var out = [];
        for (var el of els) {
          var text = (el.textContent || "").trim();
          if (text.length > 0 && text.length < 60) {
            out.push({
              tag: el.tagName,
              text: text,
              onclick: el.getAttribute("onclick") || "",
              href: el.getAttribute("href") || ""
            });
          }
        }
        return JSON.stringify(out);
      })();
    ''');
    print('SAP_DEBUG [NavDump]: $dump');
  }

  Future<Map<String, dynamic>?> extractAttendance(String year, String session) async {
    if (_extractorJs != null) {
      await _controller?.evaluateJavascript(source: _extractorJs!);
    }

    final script = '''
      (async function() {
        try {
          const result = await extractAttendance("$year", "$session");
          window.flutter_inappwebview.callHandler('attendanceResult', JSON.stringify(result));
        } catch (e) {
          window.flutter_inappwebview.callHandler('attendanceResult', JSON.stringify({ success: false, error: e.message || e.toString(), data: null }));
        }
      })();
    ''';

    try {
      _pendingAttendanceCompleter = Completer<String?>();
      await _controller?.evaluateJavascript(source: script);
      
      final result = await _pendingAttendanceCompleter!.future.timeout(
        const Duration(seconds: 45),
        onTimeout: () => null,
      );
      
      if (result == null) {
        return {'success': false, 'error': 'No result returned from extraction script (timeout or null)', 'data': null};
      }
      
      Map<String, dynamic> resultMap;
      try {
        resultMap = jsonDecode(result) as Map<String, dynamic>;
      } catch (e) {
        return {'success': false, 'error': 'Failed to parse JSON result: $e', 'data': null};
      }
      return resultMap;
    } catch (e) {
      return {'success': false, 'error': 'Extraction error: $e', 'data': null};
    }
  }

  Future<void> clearSessionData() async {
    try {
      final cookieManager = CookieManager.instance();
      await cookieManager.deleteAllCookies();
      if (_controller != null) {
        await _controller?.clearCache();
      }
    } catch (e) {
      print('SAP_DEBUG [Scraper]: Error clearing session cookies & cache: $e');
    }
  }

  Future<void> dispose() async {
    await clearSessionData();
    _headlessWebView?.dispose();
    _headlessWebView = null;
    _controller = null;
    isPageLoaded.value = false;
  }
}
