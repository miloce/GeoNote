export type ColorToken =
  | 'pageBackground'
    | 'cardBackground'
    | 'textPrimary'
    | 'textLink'
    | 'buttonPrimaryBg'
    | 'buttonPrimaryText'
    | 'textMuted'
    | 'divider'
    | 'textInverse'
    | 'authPageBackground'
    | 'authCardBackground'
    | 'authButtonBg'
    | 'authButtonText'
    | 'footprintCardGradientStart'
    | 'footprintCardGradientEnd'
    | 'footprintCardDecoration'
    | 'footprintCardShadow';

interface TokenMap {
  pageBackground: string;
  cardBackground: string;
  textPrimary: string;
  textLink: string;
  buttonPrimaryBg: string;
  buttonPrimaryText: string;
  textMuted: string;
  divider: string;
  textInverse: string;
  authPageBackground: string;
  authCardBackground: string;
  authButtonBg: string;
  authButtonText: string;
  footprintCardGradientStart: string;
  footprintCardGradientEnd: string;
  footprintCardDecoration: string;
  footprintCardShadow: string;
}

const tokenMap: TokenMap = {
  pageBackground: 'page_background',
  cardBackground: 'card_background',
  textPrimary: 'text_primary',
  textLink: 'text_link',
  buttonPrimaryBg: 'button_primary_bg',
  buttonPrimaryText: 'button_primary_text',
  textMuted: 'text_muted',
  divider: 'divider',
  textInverse: 'text_inverse',
  authPageBackground: 'auth_page_background',
  authCardBackground: 'auth_card_background',
  authButtonBg: 'auth_button_bg',
  authButtonText: 'auth_button_text',
  footprintCardGradientStart: 'footprint_card_gradient_start',
  footprintCardGradientEnd: 'footprint_card_gradient_end',
  footprintCardDecoration: 'footprint_card_decoration',
  footprintCardShadow: 'footprint_card_shadow'
};

export class ColorTheme {
  static getColor(token: ColorToken): ResourceColor {
    switch (token) {
      case 'pageBackground':
        return $r(`app.color.${tokenMap.pageBackground}`);
      case 'cardBackground':
        return $r(`app.color.${tokenMap.cardBackground}`);
      case 'textPrimary':
        return $r(`app.color.${tokenMap.textPrimary}`);
      case 'textLink':
        return $r(`app.color.${tokenMap.textLink}`);
      case 'buttonPrimaryBg':
        return $r(`app.color.${tokenMap.buttonPrimaryBg}`);
      case 'buttonPrimaryText':
        return $r(`app.color.${tokenMap.buttonPrimaryText}`);
      case 'textMuted':
        return $r(`app.color.${tokenMap.textMuted}`);
      case 'divider':
        return $r(`app.color.${tokenMap.divider}`);
      case 'textInverse':
        return $r(`app.color.${tokenMap.textInverse}`);
      case 'authPageBackground':
        return $r(`app.color.${tokenMap.authPageBackground}`);
      case 'authCardBackground':
        return $r(`app.color.${tokenMap.authCardBackground}`);
      case 'authButtonBg':
        return $r(`app.color.${tokenMap.authButtonBg}`);
      case 'authButtonText':
        return $r(`app.color.${tokenMap.authButtonText}`);
      case 'footprintCardGradientStart':
        return $r(`app.color.${tokenMap.footprintCardGradientStart}`);
      case 'footprintCardGradientEnd':
        return $r(`app.color.${tokenMap.footprintCardGradientEnd}`);
      case 'footprintCardDecoration':
        return $r(`app.color.${tokenMap.footprintCardDecoration}`);
      case 'footprintCardShadow':
        return $r(`app.color.${tokenMap.footprintCardShadow}`);
      default:
        return $r('app.color.page_background');
    }
  }
}
