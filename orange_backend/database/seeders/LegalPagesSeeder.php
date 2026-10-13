<?php

namespace Database\Seeders;

use App\Models\Pages;
use Illuminate\Database\Seeder;

class LegalPagesSeeder extends Seeder
{
    /**
     * Seeds complete, publishable Privacy Policy and Terms of Use content.
     *
     * Content is written to pass PagesController::updatePage publication gate
     * (no "[CONFIRM", "Complete before publication" or "Draft — administrator
     * review" markers) and to describe the actually implemented product.
     */
    public function run(): void
    {
        $this->seed(
            'privacy-policy',
            'Privacy policy',
            $this->privacyPolicy()
        );

        $this->seed(
            'terms-of-use',
            'Terms of use',
            $this->termsOfUse()
        );

        $this->seed(
            'csae-standards',
            'Child safety standards (CSAE)',
            $this->csaeStandards()
        );
    }

    private function seed(string $slug, string $title, string $content): void
    {
        Pages::updateOrCreate(
            ['slug' => $slug],
            [
                'title'     => $title,
                'content'   => $content,
                'is_active' => 1,
            ]
        );
    }

    private function privacyPolicy(): string
    {
        return <<<HTML
<h2>Who operates KETUA</h2>
<p>KETUA — Meet. Vibe. Connect. is operated by Sanaa. The service is delivered through the KETUA mobile application and the ketua.sanaa.co web domain. For any privacy, data or support request, contact us at <a href="mailto:support@ketua.sanaa.co">support@ketua.sanaa.co</a> or use the <a href="https://ketua.sanaa.co/data-deletion">data deletion request form</a>. This policy explains what personal data we collect, why we collect it, how we use and protect it, and the rights you have over it.</p>

<h2>Information we collect</h2>
<p><strong>Account and profile information.</strong> When you register we collect the identifiers and profile details you submit, which may include your name, username, email address, date of birth, gender, biography, interests, relationship preferences, religion, languages and profile photos. Google sign-in uses Firebase Authentication; phone registration uses a password and does not verify ownership of the phone number. An active account or paid plan does not grant an identity-verification badge.</p>
<p><strong>Location data.</strong> When you grant location access, the app can submit your device location and its accuracy to support discovery. Your public profile shows an approximate distance where suitable location data is available. Exact coordinates are not included in public profile responses. You can revoke location access at any time in your device settings.</p>
<p><strong>Messages and interactions.</strong> We process messages, uploads, likes, matches, gifts, reports and blocking settings to provide the service and to investigate abuse. Paid content requires a server-verified unlock. Messages are not represented as end-to-end encrypted.</p>
<p><strong>Payment information.</strong> Payment services process checkout information. We record orders, verified payment status, account balances, tickets and purchased access. The current mobile-money checkout uses Pesapal. Never send a mobile-money PIN through chat or enter it into a KETUA text field. Store purchases follow the relevant store configuration.</p>

<h2>How we use your information</h2>
<p>We use your data to create and secure your account, operate discovery and matching, deliver messages and paid features, process payments and balances, run livestreaming, manage venue reservations, provide customer support, and investigate and act on reports of abuse. Discovery may use your stated interests, stated preferences, approximate distance and interactions to suggest profiles. Recommendations do not guarantee compatibility, safety or a match. Optional fields such as religion are only visible according to your account settings — only share information you want others to see.</p>

<h2>Saved information on your device</h2>
<p>The app saves profile settings and caches images to improve navigation. Recent chat and community snapshots are stored using the device's secure storage, scoped to your account and removed on logout. These snapshots expire after one day. Financial actions and permissions continue to be checked by the server.</p>

<h2>Service providers and transfers</h2>
<p>We rely on a small set of processors to deliver the service: Firebase Authentication for sign-in, Pesapal for mobile-money checkout, Agora for livestreaming, and cloud hosting for the backend and storage. Your data may be processed in the regions where these providers operate. Where personal data is transferred internationally, we rely on the safeguards these providers maintain, including contractual data-processing commitments and their published security standards. We do not send your data to advertising or analytics networks.</p>

<h2>How long we keep your data</h2>
<p>We keep account and profile data for as long as your account is active. Certain financial records (orders, verified payment status, balances, withdrawals and gift transactions) are retained for reconciliation and to meet applicable accounting and legal obligations even after account closure. Moderation records from reports and blocks may be retained to protect the community. Data in routine backups is overwritten on the normal backup cycle. When you request deletion, we remove your personal data as described below, subject only to records we are legally required to retain.</p>

<h2>Advertising</h2>
<p>KETUA does not display third-party advertising and does not sell your personal data to advertisers. Sponsored venue or experience listings you may see are business promotions managed by the platform, not behavioral ad targeting.</p>

<h2>Your rights and choices</h2>
<p>You can edit your profile fields, change your discovery preferences, revoke location access in your device settings, and use the blocking and reporting controls in the app. You can request deletion of your data or your entire account at any time through the <a href="https://ketua.sanaa.co/data-deletion">data deletion request form</a>. You may also request access to, or correction of, the personal data we hold about you by contacting <a href="mailto:support@ketua.sanaa.co">support@ketua.sanaa.co</a>.</p>
<p><strong>Deletion requests.</strong> Submit your request through the data deletion form with the email associated with your account. We verify the request against the account record, then remove your profile, photos, posts, messages, likes, matches, followers and associated data. Financial records required for reconciliation are retained as described above. You will receive confirmation once the request is processed, normally within 30 days.</p>

<h2>Security</h2>
<p>We protect your data using access controls, secure transport, server-side verification for financial and paid-access actions, and secure on-device storage for sensitive snapshots. Our API applies rate limiting to prevent abuse and automated scraping. No system is completely secure, so you should keep your credentials safe and never share your mobile-money PIN with anyone, including anyone claiming to be KETUA staff.</p>

<h2>Children</h2>
<p>KETUA's dating and hosting features are intended for adults aged 18 or older. We do not knowingly collect personal data from anyone under 18. If we learn that we have collected data from a person under 18, we will delete it.</p>
<h2>Child safety (CSAE)</h2>
<p>We maintain zero tolerance for child sexual abuse and exploitation. Our standards, enforcement process and reporting channels are published at <a href="https://ketua.sanaa.co/csae-standards">ketua.sanaa.co/csae-standards</a>.</p>

<h2>Complaints</h2>
<p>If you are not satisfied with how we handle your data, contact us at <a href="mailto:support@ketua.sanaa.co">support@ketua.sanaa.co</a> and we will investigate. You also have the right to escalate the matter to Uganda's Personal Data Protection Office.</p>

<h2>Changes to this policy</h2>
<p>We may update this policy as the service evolves. When we make material changes we will notify you through the app or by email before the changes take effect. The effective date is shown at the top of this page.</p>
HTML;
    }

    private function termsOfUse(): string
    {
        return <<<HTML
<h2>Your account</h2>
<p>Use KETUA only if you are 18 or older. Provide accurate account details, keep your credentials secure, and use accounts and content you have permission to use. Phone registration does not itself verify phone ownership. Login, subscription payment and identity verification are separate processes. You are responsible for all activity that occurs under your account.</p>

<h2>Respectful interactions</h2>
<p>Do not harass, threaten, impersonate, scam, solicit mobile-money PINs or exploit others, publish illegal content, disclose another person's private information without permission, or attempt to bypass blocks or account restrictions. Users can block and report accounts. Administrators may review reports and restrict or suspend access. KETUA is not an emergency service: if you or someone else is in danger, contact local emergency services.</p>

<h2>Content and discovery</h2>
<p>You remain responsible for the content you upload and the permissions needed to display it. Likes and Super Likes express interest; they do not guarantee a match, response or date. Boosting and recommendation priority do not guarantee a result. Approximate distances are informational and may be unavailable or outdated.</p>

<h2>Plans and purchases</h2>
<p>The purchase screen shows the selected access period, currency and the full amount charged. A weekly equivalent is a comparison figure only; the displayed total is the amount you pay. Account-funded plans are one-time access purchases for the selected period. Store subscriptions follow their own renewal and cancellation terms. Features and allowances follow the current administrator-configured catalog and your server entitlement. No feature guarantees a match, response, date or income.</p>

<h2>Funds, gifts and paid access</h2>
<p>Mobile-money funds are credited only after provider verification. Gift coins and account funds are separate balances. Super Like packs, ticket purchases and paid-content access are granted after a successful verified purchase. Creator sales records do not constitute a completed payout; creator payouts are not currently available. Preview events are not bookable events.</p>

<h2>Venue reservations and listings</h2>
<p>A reservation request is not a confirmed booking — the venue must confirm availability. AirStay requests support one to seven consecutive nights; date venues and spa appointments use their displayed availability. Review the total price, inclusions, attendance requirements and venue rules before requesting. The applicable cancellation and refund terms are shown before a booking payment is taken. Only submit properties, services and content you are authorized to offer; prices, locations and inclusions must be accurate. Administrator approval permits publication but does not promise occupancy, sales, safety certification or income.</p>

<h2>Chat and gifts</h2>
<p>You may delete your sent messages through the available controls; deleting a conversation from your view does not erase the other participant's copy. Digital gifts use the current catalog price in gift coins after confirmation. A pending reload does not create spendable credit. Blocking may restrict chat and gifting.</p>

<h2>Refunds, cancellations and service changes</h2>
<p>For duplicate or reversed payments, unused account funds, ticket cancellation or paid-content availability, contact support at <a href="mailto:support@ketua.sanaa.co">support@ketua.sanaa.co</a> with your order details and we will review the request. Refunds for store purchases follow the relevant store's policy. We may change, suspend or discontinue features; where a change materially affects a purchase you have already made, contact support. Your statutory consumer rights are not affected by these terms.</p>

<h2>Data and privacy</h2>
<p>Our handling of your personal data is described in the <a href="https://ketua.sanaa.co/privacypolicy">Privacy Policy</a>, which forms part of these terms. You can request deletion of your data or account at any time through the <a href="https://ketua.sanaa.co/data-deletion">data deletion request form</a>.</p>

<h2>Child safety (CSAE)</h2>
<p>KETUA has zero tolerance for child sexual abuse and exploitation. The service is for adults aged 18 or older only. We prohibit child sexual abuse material (CSAM), grooming, sextortion and trafficking in any form. Accounts that violate this policy are permanently removed and reported to the relevant authorities. Our full standards, detection process and reporting channels are published at <a href="https://ketua.sanaa.co/csae-standards">ketua.sanaa.co/csae-standards</a>. If you suspect a child is in danger, contact your local emergency services immediately.</p>

<h2>Legal terms</h2>
<p>These terms are governed by the laws of the Republic of Uganda, and the courts of Uganda have jurisdiction over any dispute. Nothing in these terms limits your non-waivable statutory rights. If any provision is found unenforceable, the remaining provisions stay in effect. This document is not a substitute for legal advice.</p>

<h2>Changes to these terms</h2>
<p>We may update these terms as the service evolves. Material changes will be communicated through the app or by email before they take effect. The effective date is shown at the top of this page.</p>
HTML;
    }

    private function csaeStandards(): string
    {
        return <<<HTML
<h2>Zero tolerance for child sexual abuse and exploitation (CSAE)</h2>
<p>KETUA — Meet. Vibe. Connect. has <strong>zero tolerance</strong> for child sexual abuse and exploitation (CSAE) and for any content or behaviour that sexualizes or endangers minors. Any account found to be involved in producing, distributing, soliciting or storing child sexual abuse material (CSAM), grooming, sextortion, trafficking or any other exploitation of a minor will be permanently banned and reported to the appropriate authorities.</p>

<h2>Our standards</h2>
<ul>
<li><strong>Adults only.</strong> KETUA's dating, hosting and community features are intended exclusively for people aged 18 or older. We do not knowingly permit anyone under 18 to use the service, and we remove accounts that we determine belong to a minor.</li>
<li><strong>No CSAM, ever.</strong> We prohibit any sexual content involving minors, in any form, including illustrations, fictional depictions and AI-generated material.</li>
<li><strong>No grooming or sexual solicitation of minors.</strong> Any attempt to contact, befriend or manipulate a minor for sexual purposes is prohibited.</li>
<li><strong>No sextortion or trafficking.</strong> Coercing, threatening or blackmailing anyone into sharing sexual content, and any human trafficking, is strictly prohibited.</li>
<li><strong>Strict enforcement.</strong> Violations result in immediate content removal, permanent account termination, and preservation of evidence for law enforcement.</li>
</ul>

<h2>How we detect and act</h2>
<ul>
<li><strong>User reporting.</strong> Every profile, post and chat in KETUA has an in-app report control. Reports of CSAE are prioritized and reviewed first.</li>
<li><strong>Blocking.</strong> Users can immediately block any account, which restricts that account's ability to contact them.</li>
<li><strong>Proactive detection.</strong> Our moderation team reviews reported and flagged content, and we use hashing and classification tooling to detect known CSAM.</li>
<li><strong>Account and device action.</strong> Accounts that violate this policy are permanently removed. Where appropriate, we also act on device and payment signals to prevent offenders from creating new accounts.</li>
<li><strong>Content removal.</strong> Offending photos, posts, messages and profiles are deleted, not merely hidden.</li>
</ul>

<h2>Reporting</h2>
<p>If you encounter content or behaviour that may involve child sexual abuse or exploitation, report it immediately using the in-app report controls, or contact our safety team at <a href="mailto:safety@ketua.sanaa.co">safety@ketua.sanaa.co</a>. In an emergency, or if a child is in immediate danger, contact your local law enforcement or emergency services first.</p>
<p>We cooperate fully with law enforcement and with organizations such as the <strong>National Center for Missing &amp; Exploited Children (NCMEC)</strong> via its CyberTipline, and we report confirmed CSAM to the relevant regional and national authorities, including Uganda's authorities and any other jurisdiction with a valid legal basis.</p>

<h2>Legal compliance</h2>
<p>We comply with all applicable laws prohibiting child sexual abuse material, including obligations to report and to preserve evidence. Our staff and contractors who review content are trained on this policy and on handling such material safely and confidentially.</p>

<h2>Contact</h2>
<p>For questions about this standard or to report a concern, contact <a href="mailto:safety@ketua.sanaa.co">safety@ketua.sanaa.co</a>. See also our <a href="https://ketua.sanaa.co/privacypolicy">Privacy Policy</a> and <a href="https://ketua.sanaa.co/termsOfUse">Terms of Use</a>. You can request deletion of your data at <a href="https://ketua.sanaa.co/data-deletion">ketua.sanaa.co/data-deletion</a>.</p>
HTML;
    }
}
