/// <exclude />
{$I TaurusTLSCompilerDefines.inc}
{$I TaurusTLSLinkDefines.inc}
{$IFNDEF USE_OPENSSL}
{ error Should not compile if USE_OPENSSL is not defined!!! }
{$ENDIF}
{ ****************************************************************************** }
{ *  TaurusTLS                                                                 * }
{ *           https://github.com/JPeterMugaas/TaurusTLS                        * }
{ *                                                                            * }
{ *  Copyright (c) 2026 TaurusTLS Developers, All Rights Reserved              * }
{ *                                                                            * }
{ * Portions of this software are Copyright (c) 1993 – 2018,                   * }
{ * Chad Z. Hower (Kudzu) and the Indy Pit Crew – http://www.IndyProject.org/  * }
{ ****************************************************************************** }

unit TaurusTLSHeaders_prov_ssl;

interface
const
//* SSL/TLS related defines useful to providers */
  SSL_MAX_MASTER_KEY_LENGTH = 48;

//* SSL/TLS uses a 2 byte unsigned version number */
  SSL3_VERSION = $0300;
  TLS1_VERSION = $0301;
  TLS1_1_VERSION = $0302;
  TLS1_2_VERSION = $0303;
  TLS1_3_VERSION = $0304;
  DTLS1_VERSION = $FEFF;
  DTLS1_2_VERSION = $FEFD;
  DTLS1_3_VERSION = $FEFC;
  DTLS1_BAD_VER = $0100;

  PROTO_VERSION_UNSET = 0;

//* QUIC uses a 4 byte unsigned version number */
  OSSL_QUIC1_VERSION = $0000001;

//* Maximum plaintext length: defined by SSL/TLS standards */
  SSL3_RT_MAX_PLAIN_LENGTH = 16384;

implementation

end.
