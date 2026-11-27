import 'package:flutter_test/flutter_test.dart';
import 'package:velora_mobile/core/config/app_config.dart';
import 'package:velora_mobile/core/config/business_vertical.dart';
import 'package:velora_mobile/features/auth/auth_service.dart';

void main() {
  setUpAll(() {
    AppConfig.initialize(
      AppConfig(
        flavor: AppFlavor.fnb,
        appName: 'Velora POS',
      ),
    );
  });

  group('BusinessVertical.resolve routing', () {
    test('routes pbf and pharmacy business types to BusinessVertical.pharmacy', () {
      expect(
        BusinessVertical.resolve(businessType: 'pbf', flavor: AppFlavor.fnb),
        BusinessVertical.pharmacy,
      );
      expect(
        BusinessVertical.resolve(businessType: 'pharmacy', flavor: AppFlavor.fnb),
        BusinessVertical.pharmacy,
      );
      expect(
        BusinessVertical.resolve(businessType: 'apotek', flavor: AppFlavor.fnb),
        BusinessVertical.pharmacy,
      );
    });

    test('routes cafe to fnb and retail to retail', () {
      expect(
        BusinessVertical.resolve(businessType: 'cafe', flavor: AppFlavor.fnb),
        BusinessVertical.fnb,
      );
      expect(
        BusinessVertical.resolve(businessType: 'retail', flavor: AppFlavor.fnb),
        BusinessVertical.retail,
      );
    });

    test('dedicated flavor overrides take precedence', () {
      expect(
        BusinessVertical.resolve(businessType: 'cafe', flavor: AppFlavor.pharmacy),
        BusinessVertical.pharmacy,
      );
      expect(
        BusinessVertical.resolve(businessType: 'cafe', flavor: AppFlavor.sales),
        BusinessVertical.sales,
      );
    });
  });

  group('AuthPublicSettings.fromJson', () {
    test('parses flags and dynamic registration_schema for pharmacy and pbf', () {
      final settings = AuthPublicSettings.fromJson({
        'allow_public_registration': false,
        'allow_password_reset': false,
        'maintenance_mode': true,
        'enable_google_auth': false,
        'registration_schema': {
          'pbf': {
            'label': 'PBF (Distributor)',
            'business_name_label': 'Nama PBF / Distributor',
            'extra_fields': [
              {
                'key': 'sia_number',
                'label': 'Nomor Izin PBF / Sertifikat Distribusi',
                'required': true,
              },
              {
                'key': 'npwp_number',
                'label': 'NPWP',
                'required': false,
              },
            ],
          },
        },
      });

      expect(settings.allowPublicRegistration, isFalse);
      expect(settings.allowPasswordReset, isFalse);
      expect(settings.maintenanceMode, isTrue);
      expect(settings.enableGoogleAuth, isFalse);

      final pbfSchema = settings.schemaFor('pbf');
      expect(pbfSchema.label, 'PBF (Distributor)');
      expect(pbfSchema.businessNameLabel, 'Nama PBF / Distributor');
      expect(pbfSchema.extraFields.length, 2);
      expect(pbfSchema.extraFields.first.key, 'sia_number');
      expect(pbfSchema.extraFields.first.required, isTrue);
    });
  });
}
