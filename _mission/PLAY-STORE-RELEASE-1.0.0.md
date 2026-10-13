# KETUA first Play Store bundle

Package/application ID: `com.sanyu.ketua`. App label: KETUA. Release version: `1.0.0`, version code `4018`. The internal code stays above the earlier device test builds. Future uploads must use a greater code. Minimum Android API 24; target and compile API 36.

A dedicated RSA-4096 upload key was created for this first Play release. Release Gradle tasks now refuse to run without the private signing properties path and never fall back to development signing. Keystore and passwords are outside the repository and outside web roots, with restricted file permissions. An existing legacy vendor keystore was not reused. This key assumes this is the first Play upload for this package; an already registered application must use its authorized upload key.

Private signing backup on the Mac: `/Users/banks.sanaa/.config/ketua/release-signing/`. Keep the keystore and its properties file together in a secure backup. Public upload certificate: `ketua-upload-certificate.pem`. Server copy: `/var/lib/ketua-release-signing/`. No signing secrets are embedded in the downloadable bundle.

The upload certificate was registered in Firebase project `ketua-750dc` for `com.sanyu.ketua`, and Android public configuration was refreshed. When Play App Signing is enabled, add the **app signing** SHA-1 and SHA-256 from Play Console → App integrity to this same Firebase Android app, then refresh its Android configuration if Google changes the OAuth client. The upload certificate and Google’s app signing certificate are different identities; registering only the upload key does not complete Google sign-in for Play-installed apps.

Unused audio-media reading and Do Not Disturb permission declarations were removed. Legacy external storage writing is capped at Android API 28, and camera hardware is optional so gallery-capable devices are not excluded. Image/video access still needs accurate Play Console declarations and review for the app’s photo/content workflows. Audio recording remains for live/video functionality; chat does not gain audio-message sending.

Upload the `.aab` to **Internal testing** first. It is an upload artifact, not a directly installable APK. Complete app access, content rating, target audience, Data safety, deletion URL, permissions, store listing and privacy declarations accurately. Review and publish the legal drafts before submitting for public review. Dating/UGC moderation and child-safety declarations, real provider acceptance, billing routes for digital goods, creator payouts and genuine inventory remain launch gates recorded in the readiness audit. Building/signing does not establish approval or public market readiness.

The new release certificate differs from the prior development-signed OPPO installation. Do not uninstall that installation without preserving any needed local drafts/data. This build has not been installed over it and is not described as a complete release-mode device certification.

## Rebuild

Set `KETUA_UPLOAD_PROPERTIES` to the private properties file and `KETUA_FLUTTER` to the configured Flutter executable, then run `Orange/android/build-play-release.sh`. The current reviewed server has the resolved dependencies; a clean checkout must restore dependencies first. Never commit the key/properties files or place them in public downloads.

## Verification and download

Release build succeeded in 1102.4 seconds. Official bundletool 1.18.3 validation passed, JAR signature verifies against the dedicated upload certificate, and the final manifest confirms package/version/code/API 36 with debugging disabled. All 66 ARM64/x86-64 native libraries passed ELF 16 KB alignment checks; the bundle includes ARMv7, ARM64 and x86-64. ZIP integrity passes and no keystore/signing properties are packaged. These packaging checks do not replace Play pre-launch/device testing on 16 KB systems.

[Download signed Play Store bundle](https://ketua.sanaa.co/downloads/ketua-play-1-99b26c3b9ecd6c81/KETUA-1.0.0-play-store.aab). Local file: `evidence/play-release/KETUA-1.0.0-play-store.aab`. Size: 229,070,271 bytes (about 229 MB). SHA-256: `99b26c3b9ecd6c817f63c2924c62103efecf90f058b8992898e4e643af1b7561`. Public HTTPS responds 200 with the exact size; local copy hash matches. Only the bundle was published; the signing key/passwords remain private.

Build logs include AGP/Kotlin future-support warnings and a file-watcher warning; the command completed successfully. Existing release readiness gaps remain documented. Google’s Play signing certificate registration is a required next step once the Play application is initialized.
