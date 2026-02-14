import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class AuthService {
  final http.Client _client;

  AuthService({http.Client? client}) : _client = client ?? http.Client();

  String get _graphqlEndpoint =>
      'https://${AppConstants.shopifyStoreDomain}/api/2024-01/graphql.json';

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'X-Shopify-Storefront-Access-Token':
            AppConstants.shopifyStorefrontAccessToken,
      };

  /// Register a new customer via Shopify Storefront API.
  Future<AuthResult> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    const mutation = '''
      mutation customerCreate(\$input: CustomerCreateInput!) {
        customerCreate(input: \$input) {
          customer {
            id
            firstName
            lastName
            email
          }
          customerUserErrors {
            field
            message
            code
          }
        }
      }
    ''';

    final variables = {
      'input': {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
      },
    };

    try {
      final response = await _client.post(
        Uri.parse(_graphqlEndpoint),
        headers: _headers,
        body: json.encode({'query': mutation, 'variables': variables}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final result = data['data']?['customerCreate'];

        if (result == null) {
          return AuthResult.failure('Unexpected response from server.');
        }

        final errors = result['customerUserErrors'] as List?;
        if (errors != null && errors.isNotEmpty) {
          final message =
              errors.map((e) => e['message'] as String).join(', ');
          return AuthResult.failure(message);
        }

        // Registration successful — now log them in automatically
        return login(email: email, password: password);
      }

      return AuthResult.failure('Server error (${response.statusCode}).');
    } catch (e) {
      return AuthResult.failure('Network error. Please try again.');
    }
  }

  /// Log in an existing customer via Shopify Storefront API.
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    const mutation = '''
      mutation customerAccessTokenCreate(\$input: CustomerAccessTokenCreateInput!) {
        customerAccessTokenCreate(input: \$input) {
          customerAccessToken {
            accessToken
            expiresAt
          }
          customerUserErrors {
            field
            message
            code
          }
        }
      }
    ''';

    final variables = {
      'input': {
        'email': email,
        'password': password,
      },
    };

    try {
      final response = await _client.post(
        Uri.parse(_graphqlEndpoint),
        headers: _headers,
        body: json.encode({'query': mutation, 'variables': variables}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final result = data['data']?['customerAccessTokenCreate'];

        if (result == null) {
          return AuthResult.failure('Unexpected response from server.');
        }

        final errors = result['customerUserErrors'] as List?;
        if (errors != null && errors.isNotEmpty) {
          final message =
              errors.map((e) => e['message'] as String).join(', ');
          return AuthResult.failure(message);
        }

        final token = result['customerAccessToken'];
        if (token != null) {
          final accessToken = token['accessToken'] as String;
          final customer = await fetchCustomer(accessToken);
          return AuthResult.success(
            accessToken: accessToken,
            customer: customer,
          );
        }

        return AuthResult.failure('Failed to create access token.');
      }

      return AuthResult.failure('Server error (${response.statusCode}).');
    } catch (e) {
      return AuthResult.failure('Network error. Please try again.');
    }
  }

  /// Fetch customer details using access token.
  Future<CustomerInfo?> fetchCustomer(String accessToken) async {
    const query = '''
      query {
        customer(customerAccessToken: "\$token") {
          id
          firstName
          lastName
          email
          phone
        }
      }
    ''';

    try {
      final response = await _client.post(
        Uri.parse(_graphqlEndpoint),
        headers: _headers,
        body: json.encode({
          'query': query.replaceAll('\$token', accessToken),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final customer = data['data']?['customer'];
        if (customer != null) {
          return CustomerInfo(
            id: customer['id'] as String,
            firstName: customer['firstName'] as String? ?? '',
            lastName: customer['lastName'] as String? ?? '',
            email: customer['email'] as String? ?? '',
            phone: customer['phone'] as String?,
          );
        }
      }
    } catch (_) {
      // Silently fail — user is still authenticated
    }
    return null;
  }

  /// Update customer profile details.
  Future<ServiceResult> updateCustomer({
    required String accessToken,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    const mutation = '''
      mutation customerUpdate(\$customerAccessToken: String!, \$customer: CustomerUpdateInput!) {
        customerUpdate(customerAccessToken: \$customerAccessToken, customer: \$customer) {
          customer {
            id
            firstName
            lastName
            email
            phone
          }
          customerUserErrors {
            field
            message
            code
          }
        }
      }
    ''';

    final customerInput = <String, dynamic>{
      'firstName': firstName,
      'lastName': lastName,
    };
    if (phone != null) {
      customerInput['phone'] = phone;
    }

    final variables = {
      'customerAccessToken': accessToken,
      'customer': customerInput,
    };

    try {
      final response = await _client.post(
        Uri.parse(_graphqlEndpoint),
        headers: _headers,
        body: json.encode({'query': mutation, 'variables': variables}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final result = data['data']?['customerUpdate'];

        if (result == null) {
          return ServiceResult.failure('Unexpected response from server.');
        }

        final errors = result['customerUserErrors'] as List?;
        if (errors != null && errors.isNotEmpty) {
          final message =
              errors.map((e) => e['message'] as String).join(', ');
          return ServiceResult.failure(message);
        }

        return ServiceResult.success();
      }

      return ServiceResult.failure('Server error (${response.statusCode}).');
    } catch (e) {
      return ServiceResult.failure('Network error. Please try again.');
    }
  }

  /// Change the customer's password.
  Future<ServiceResult> changePassword({
    required String accessToken,
    required String newPassword,
  }) async {
    const mutation = '''
      mutation customerUpdate(\$customerAccessToken: String!, \$customer: CustomerUpdateInput!) {
        customerUpdate(customerAccessToken: \$customerAccessToken, customer: \$customer) {
          customer {
            id
          }
          customerUserErrors {
            field
            message
            code
          }
        }
      }
    ''';

    final variables = {
      'customerAccessToken': accessToken,
      'customer': {
        'password': newPassword,
      },
    };

    try {
      final response = await _client.post(
        Uri.parse(_graphqlEndpoint),
        headers: _headers,
        body: json.encode({'query': mutation, 'variables': variables}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final result = data['data']?['customerUpdate'];

        if (result == null) {
          return ServiceResult.failure('Unexpected response from server.');
        }

        final errors = result['customerUserErrors'] as List?;
        if (errors != null && errors.isNotEmpty) {
          final message =
              errors.map((e) => e['message'] as String).join(', ');
          return ServiceResult.failure(message);
        }

        return ServiceResult.success();
      }

      return ServiceResult.failure('Server error (${response.statusCode}).');
    } catch (e) {
      return ServiceResult.failure('Network error. Please try again.');
    }
  }

  /// Send a password reset email via Shopify Storefront API.
  Future<ServiceResult> recoverPassword({required String email}) async {
    const mutation = '''
      mutation customerRecover(\$email: String!) {
        customerRecover(email: \$email) {
          customerUserErrors {
            field
            message
            code
          }
        }
      }
    ''';

    final variables = {'email': email};

    try {
      final response = await _client.post(
        Uri.parse(_graphqlEndpoint),
        headers: _headers,
        body: json.encode({'query': mutation, 'variables': variables}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final result = data['data']?['customerRecover'];

        if (result == null) {
          return ServiceResult.failure('Unexpected response from server.');
        }

        final errors = result['customerUserErrors'] as List?;
        if (errors != null && errors.isNotEmpty) {
          final message =
              errors.map((e) => e['message'] as String).join(', ');
          return ServiceResult.failure(message);
        }

        return ServiceResult.success();
      }

      return ServiceResult.failure('Server error (${response.statusCode}).');
    } catch (e) {
      return ServiceResult.failure('Network error. Please try again.');
    }
  }

  /// Verify if a stored access token is still valid.
  Future<bool> verifyToken(String accessToken) async {
    const query = '''
      query {
        customer(customerAccessToken: "\$token") {
          id
        }
      }
    ''';

    try {
      final response = await _client.post(
        Uri.parse(_graphqlEndpoint),
        headers: _headers,
        body: json.encode({
          'query': query.replaceAll('\$token', accessToken),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data['data']?['customer'] != null;
      }
    } catch (_) {
      // Token verification failed
    }
    return false;
  }

  /// Log out by deleting the access token on Shopify.
  Future<void> logout(String accessToken) async {
    const mutation = '''
      mutation customerAccessTokenDelete(\$customerAccessToken: String!) {
        customerAccessTokenDelete(customerAccessToken: \$customerAccessToken) {
          deletedAccessToken
          userErrors {
            field
            message
          }
        }
      }
    ''';

    try {
      await _client.post(
        Uri.parse(_graphqlEndpoint),
        headers: _headers,
        body: json.encode({
          'query': mutation,
          'variables': {'customerAccessToken': accessToken},
        }),
      );
    } catch (_) {
      // Best-effort logout
    }
  }
}

class AuthResult {
  final bool isSuccess;
  final String? accessToken;
  final CustomerInfo? customer;
  final String? error;

  AuthResult._({
    required this.isSuccess,
    this.accessToken,
    this.customer,
    this.error,
  });

  factory AuthResult.success({
    required String accessToken,
    CustomerInfo? customer,
  }) {
    return AuthResult._(
      isSuccess: true,
      accessToken: accessToken,
      customer: customer,
    );
  }

  factory AuthResult.failure(String error) {
    return AuthResult._(isSuccess: false, error: error);
  }
}

class ServiceResult {
  final bool isSuccess;
  final String? error;

  ServiceResult._({required this.isSuccess, this.error});

  factory ServiceResult.success() {
    return ServiceResult._(isSuccess: true);
  }

  factory ServiceResult.failure(String error) {
    return ServiceResult._(isSuccess: false, error: error);
  }
}

class CustomerInfo {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;

  const CustomerInfo({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
  });

  String get displayName {
    final name = '$firstName $lastName'.trim();
    return name.isNotEmpty ? name : email;
  }
}
