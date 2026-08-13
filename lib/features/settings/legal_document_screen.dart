import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../core/workloop_app_info.dart';
import '../../shared/widgets/slate_ui.dart';

enum WorkloopLegalDocument { privacy, terms }

class LegalDocumentScreen extends StatelessWidget {
  final WorkloopLegalDocument document;
  final String backSemanticLabel;

  const LegalDocumentScreen({
    super.key,
    required this.document,
    this.backSemanticLabel = 'Back to app preferences',
  });

  @override
  Widget build(BuildContext context) {
    final content = document == WorkloopLegalDocument.privacy
        ? _privacySections
        : _termsSections;
    final title = document == WorkloopLegalDocument.privacy
        ? 'Privacy policy'
        : 'Terms of use';
    final publicUrl = document == WorkloopLegalDocument.privacy
        ? WorkloopAppInfo.privacyUrl
        : WorkloopAppInfo.termsUrl;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: WorkloopTexturedBackdrop()),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageX,
                AppSpacing.lg,
                AppSpacing.pageX,
                AppSpacing.xxl,
              ),
              children: [
                WorkloopRouteHeader(
                  title: title,
                  backSemanticLabel: backSemanticLabel,
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Last updated 13 August 2026',
                  style: TextStyle(
                    color: AppColors.t3,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                for (var index = 0; index < content.length; index++) ...[
                  _LegalSection(section: content[index]),
                  if (index != content.length - 1)
                    const SizedBox(height: AppSpacing.lg),
                ],
                const SizedBox(height: AppSpacing.xl),
                WorkloopPrimaryButton(
                  label: 'Open public copy',
                  icon: LucideIcons.externalLink,
                  secondary: true,
                  onPressed: () => _openPublicCopy(context, publicUrl),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openPublicCopy(BuildContext context, String url) async {
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (opened || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('The public legal page could not be opened'),
      ),
    );
  }
}

class _LegalSection extends StatelessWidget {
  final _LegalContent section;

  const _LegalSection({required this.section});

  @override
  Widget build(BuildContext context) {
    return WorkloopSurface(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: const TextStyle(
              color: AppColors.t1,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SelectableText(
            section.body,
            style: const TextStyle(
              color: AppColors.t2,
              fontSize: 14,
              height: 1.55,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalContent {
  final String title;
  final String body;

  const _LegalContent(this.title, this.body);
}

const _privacySections = <_LegalContent>[
  _LegalContent(
    '1. Who this policy covers',
    'This policy explains how Workloop handles personal data when a solo service business owner uses the Workloop app, public profile, or support channels. Workloop is operated from the United Kingdom. Privacy questions can be sent to support@workloop.uk.',
  ),
  _LegalContent(
    '2. Data you provide',
    'We process account details, business profile and service information, working hours, client records, bookings, tasks, notes, income and expense records, and support messages. If you use Stripe payment collection, Workloop also stores connected-account and transaction references, amounts, currency, status, receipt links, and refund or dispute status needed to show and reconcile payments. When a customer asks for a contactless-payment receipt, the email address you enter is sent to Stripe for receipt delivery and may be associated with the payment record. Workloop does not receive or store full card numbers or card security codes. If you choose a device import, Workloop reads the relevant contacts or calendar events on your device to present a review list, then adds only the records you confirm to your workspace. File imports process only the files you select.',
  ),
  _LegalContent(
    '3. How data is used',
    'Data is used to authenticate you, provide and secure your workspace, connect business records into daily workflows, create exports, support public booking requests, answer support enquiries, prevent abuse, and meet legal obligations. We do not sell personal data. The current release contains no advertising SDK.',
  ),
  _LegalContent(
    '4. Legal bases',
    'Where UK or EU data-protection law applies, processing is based on performing our service contract, legitimate interests in operating and securing Workloop, legal obligations, and consent where a device permission or optional feature asks for it. Device permissions can be changed in your operating-system settings.',
  ),
  _LegalContent(
    '5. Service providers and sharing',
    'Supabase provides authentication, database, storage, and server functions. Stripe processes card payments, connected-account verification, payouts, refunds, disputes, and requested receipt delivery when you enable payment collection; Stripe receives payment, identity, and any customer receipt email you supply under its own privacy terms. Google Places may process an address search query when you use address lookup, subject to Google’s privacy policy at https://policies.google.com/privacy. Apple, Google, or your chosen device app may process information when you deliberately open a contact, calendar, map, email, or file action. We disclose data when legally required or when needed to protect users and the service.',
  ),
  _LegalContent(
    '6. Your clients’ information',
    'You decide which client information is entered into Workloop and remain responsible for having a lawful reason to use it, keeping it accurate, and responding to your clients’ rights. Do not store unnecessary sensitive information in free-text fields.',
  ),
  _LegalContent(
    '7. Retention and deletion',
    'Workspace data is kept while your account is active and as needed to provide the service. You can export your workspace and request account deletion from Settings > Account. Deletion removes the account and workspace through a protected server process, subject to limited records that must be kept for security, dispute, tax, or other legal reasons and normal backup expiry cycles.',
  ),
  _LegalContent(
    '8. Security',
    'Workloop uses authenticated access, workspace isolation, database row-level security, encrypted network transport, and protected server functions. No online service can promise absolute security, so use a strong unique password and protect access to your device.',
  ),
  _LegalContent(
    '9. Your rights',
    'Depending on where you live, you may ask to access, correct, export, restrict, object to, or erase personal data. You may also complain to your local supervisory authority; in the United Kingdom this is the Information Commissioner’s Office. Contact support@workloop.uk to exercise a right.',
  ),
  _LegalContent(
    '10. International processing',
    'Service providers may process data outside your country. Where required, appropriate contractual or legal safeguards are used for international transfers.',
  ),
  _LegalContent(
    '11. Children',
    'Workloop is a business product and is not directed to children. It must not be used by anyone under 18 to create an account.',
  ),
  _LegalContent(
    '12. Changes',
    'We may update this policy as Workloop changes. Material changes will be communicated in the app or through the account contact details where appropriate.',
  ),
];

const _termsSections = <_LegalContent>[
  _LegalContent(
    '1. Agreement',
    'These terms govern your use of Workloop. By creating an account or using the service, you agree to them and confirm that you are at least 18 and able to enter a binding agreement.',
  ),
  _LegalContent(
    '2. The service',
    'Workloop is a mobile-first business operating system for solo service businesses. It organises business records and workflows but does not replace professional legal, tax, accounting, medical, or financial advice.',
  ),
  _LegalContent(
    '3. Your account',
    'Provide accurate information, keep your login secure, and tell us promptly about suspected unauthorised access. You are responsible for activity under your account and for keeping your contact details current.',
  ),
  _LegalContent(
    '4. Business and client data',
    'You retain ownership of content you enter. You give Workloop the limited permission needed to host, process, back up, and display it to operate the service. You are responsible for the legality, accuracy, and permissions for client records, public profile content, and messages you submit.',
  ),
  _LegalContent(
    '5. Acceptable use',
    'Do not use Workloop unlawfully, to harm or mislead others, to upload malicious code, to probe or bypass security, to scrape the service, to interfere with other users, or to store content you have no right to process.',
  ),
  _LegalContent(
    '6. Public profiles and booking requests',
    'You are responsible for services, prices, availability, claims, and contact information you publish. A booking request is not automatically a confirmed contract with your client; you remain responsible for confirming the booking and your own customer terms.',
  ),
  _LegalContent(
    '7. Card payments',
    'Card collection is provided through Stripe and requires an eligible, verified connected account. You remain responsible for the services you sell, accurate prices and descriptions, customer communications, receipts, taxes, lawful refunds, and responding to disputes with appropriate evidence. Stripe controls payment acceptance, account verification, payout timing and availability, and may apply reserves, reversals, restrictions, or fees under its own agreement. Workloop is not a bank or payment institution and cannot guarantee that a payment, refund, dispute outcome, or payout will complete by a particular time.',
  ),
  _LegalContent(
    '8. Availability and exports',
    'We work to keep Workloop reliable but cannot guarantee uninterrupted availability. Maintain any records your business is legally required to keep and use the workspace export provided in Account settings as part of your own continuity process.',
  ),
  _LegalContent(
    '9. Third-party services',
    'Features may open or depend on services such as Supabase, Stripe, Google Places, maps, contacts, calendars, files, and email. Workloop includes Google Maps features and content; their use is subject to the Google Maps/Google Earth Additional Terms at https://maps.google.com/help/terms_maps/ and Google Privacy Policy at https://policies.google.com/privacy. Stripe payment services are subject to the connected-account and payment terms you accept with Stripe. Other third-party services have their own terms and availability.',
  ),
  _LegalContent(
    '10. Intellectual property',
    'Workloop’s software, visual identity, text, and service design are protected by intellectual-property law. These terms give you a personal, limited, revocable, non-transferable right to use the app for your business; they do not transfer ownership of Workloop.',
  ),
  _LegalContent(
    '11. Suspension and termination',
    'You may stop using Workloop and request account deletion. We may restrict or end access where reasonably necessary for security, illegal use, material breach, or protection of the service or others. Where practical, we will give notice and an opportunity to export data.',
  ),
  _LegalContent(
    '12. Liability',
    'Nothing in these terms excludes liability that cannot legally be excluded. To the extent permitted by law, Workloop is not responsible for indirect or consequential loss, lost profit, or business decisions made from records entered by a user. Consumer rights that apply to you remain unaffected.',
  ),
  _LegalContent(
    '13. Law, changes, and contact',
    'These terms are governed by the laws of England and Wales, subject to any mandatory rights in your home country. We may update them as the service changes and will communicate material changes where appropriate. Questions can be sent to support@workloop.uk.',
  ),
];
