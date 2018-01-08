/*
 Copyright 2015-2016 Marcel Piestansky, http://marpies.com.
 */
package feathers.themes {

    import feathers.controls.Alert;
    import feathers.controls.AutoComplete;
    import feathers.controls.Button;
    import feathers.controls.ButtonGroup;
    import feathers.controls.ButtonState;
    import feathers.controls.Callout;
    import feathers.controls.Check;
    import feathers.controls.DateTimeSpinner;
    import feathers.controls.Drawers;
    import feathers.controls.GroupedList;
    import feathers.controls.Header;
    import feathers.controls.ImageLoader;
    import feathers.controls.Label;
    import feathers.controls.LayoutGroup;
    import feathers.controls.List;
    import feathers.controls.NumericStepper;
    import feathers.controls.PageIndicator;
    import feathers.controls.Panel;
    import feathers.controls.PanelScreen;
    import feathers.controls.PickerList;
    import feathers.controls.ProgressBar;
    import feathers.controls.Radio;
    import feathers.controls.ScrollContainer;
    import feathers.controls.ScrollPolicy;
    import feathers.controls.ScrollText;
    import feathers.controls.Scroller;
    import feathers.controls.SimpleScrollBar;
    import feathers.controls.Slider;
    import feathers.controls.SpinnerList;
    import feathers.controls.StepperButtonLayoutMode;
    import feathers.controls.TabBar;
	import feathers.controls.TabNavigator;
	import feathers.controls.TextArea;
    import feathers.controls.TextCallout;
    import feathers.controls.TextInput;
    import feathers.controls.TextInputState;
    import feathers.controls.ToggleButton;
    import feathers.controls.ToggleSwitch;
    import feathers.controls.TrackLayoutMode;
    import feathers.controls.Tree;
    import feathers.controls.popups.DropDownPopUpContentManager;
    import feathers.controls.popups.VerticalCenteredPopUpContentManager;
    import feathers.controls.renderers.BaseDefaultItemRenderer;
    import feathers.controls.renderers.DefaultGroupedListHeaderOrFooterRenderer;
    import feathers.controls.renderers.DefaultGroupedListItemRenderer;
    import feathers.controls.renderers.DefaultListItemRenderer;
    import feathers.controls.renderers.DefaultTreeItemRenderer;
    import feathers.controls.supportClasses.GroupedListDataViewPort;
    import feathers.controls.supportClasses.ListDataViewPort;
    import feathers.controls.text.StageTextTextEditor;
    import feathers.controls.text.StageTextTextEditorViewPort;
    import feathers.controls.text.TextBlockTextEditor;
    import feathers.controls.text.TextBlockTextRenderer;
    import feathers.core.FeathersControl;
    import feathers.core.ITextEditor;
    import feathers.core.ITextRenderer;
    import feathers.core.PopUpManager;
    import feathers.layout.Direction;
    import feathers.layout.HorizontalAlign;
    import feathers.layout.HorizontalLayout;
    import feathers.layout.RelativePosition;
    import feathers.layout.VerticalAlign;
    import feathers.media.FullScreenToggleButton;
    import feathers.media.MuteToggleButton;
    import feathers.media.PlayPauseToggleButton;
    import feathers.media.SeekSlider;
    import feathers.media.TimeLabel;
    import feathers.media.VolumeSlider;
    import feathers.skins.ImageSkin;
    import feathers.system.DeviceCapabilities;
	import feathers.text.FontStylesSet;

	import flash.geom.Rectangle;

    import starling.animation.Transitions;

    import starling.core.Starling;
    import starling.display.DisplayObject;
    import starling.display.Image;
	import starling.display.Quad;
	import starling.text.TextFormat;
	import starling.textures.Texture;
    import starling.textures.TextureAtlas;
	import starling.utils.Align;

	/**
     * Base class for "Material DeepGreyAmber" mobile theme for Feathers. This class
     * handles all the component skinning but does not load the theme assets therefore
     * this class should not be used directly.
     *
     * <p>To use the theme with embedded assets, use either <code>MaterialDeepGreyAmberMobileTheme</code> or <code>MaterialDeepGreyAmberMobileThemeWithIcons</code>.<p>
     * <p>To use the theme with assets loaded at runtime, choose either <code>MaterialDeepGreyAmberMobileThemeWithAssetManager</code> or <code>MaterialDeepGreyAmberMobileThemeWithAssetManagerAndIcons</code>
     */
    public class BaseMaterialDeepGreyAmberMobileTheme extends StyleNameFunctionTheme {

        [Embed(source="/assets/theme/fonts/Roboto-Regular.ttf", fontFamily="Roboto", fontWeight="normal", mimeType="application/x-font", embedAsCFF="true")]
        private static const ROBOTO_REGULAR:Class;
        [Embed(source="/assets/theme/fonts/Roboto-Bold.ttf", fontFamily="Roboto", fontWeight="bold", mimeType="application/x-font", embedAsCFF="true")]
        private static const ROBOTO_BOLD:Class;

        public static const FONT_NAME:String = "Roboto";

        /* Colors */
        protected static const COLOR_UI_LIGHT:uint = 0xEEEEEE;
        protected static const COLOR_UI_EXTRA_LIGHT:uint = 0xFFFFFF;
        protected static const COLOR_UI_LIGHT_DISABLED:uint = 0x666666;
        protected static const COLOR_UI_DARK:uint = 0x333333;
        protected static const COLOR_ACCENT:uint = 0x0086ff;
        protected static const COLOR_ACCENT_DARK_50:uint = 0x7F5500; // ACCENT_DARK with 50%
        protected static const COLOR_BACKGROUND_DARK:uint = 0x20222A;
        protected static const ALPHA_MODAL_OVERLAY:Number = 0.8;

        /* Scale 9 Grids */
        protected static const BUTTON_SCALE9_GRID:Rectangle = new Rectangle( 8, 7, 1, 2 );
        protected static const BUTTON_QUIET_SCALE9_GRID:Rectangle = new Rectangle( 2, 2, 1, 32 );
        protected static const BUTTON_BACK_SCALE9_GRID:Rectangle = new Rectangle( 19.5, 5, 2, 29 );
        protected static const BUTTON_FORWARD_SCALE9_GRID:Rectangle = new Rectangle( 4, 5, 1, 29 );
        protected static const BUTTON_CALL_TO_ACTION_SCALE9_GRID:Rectangle = new Rectangle( 24.5, 23, 1, 1 );
        protected static const TOGGLE_SWITCH_THUMB_SCALE9_GRID:Rectangle = new Rectangle( 11.5, 11.5, 1, 1 );
        protected static const SLIDER_THUMB_SCALE9_GRID:Rectangle = new Rectangle( 12, 12, 1, 1 );
        protected static const PROGRESS_BAR_SCALE9_GRID:Rectangle = new Rectangle( 1, 1, 2, 2 );
        protected static const SLIDER_HORIZONTAL_SCALE9_GRID:Rectangle = new Rectangle( 0.5, 1, 2, 0.5 );
        protected static const SLIDER_VERTICAL_SCALE9_GRID:Rectangle = new Rectangle( 1, 0.5, 0.5, 2 );
        protected static const SEEK_SLIDER_SCALE9_GRID:Rectangle = new Rectangle( 0.5, 0.5, 1, 1 );
        protected static const BACKGROUND_SCALE9_GRID:Rectangle = new Rectangle( 1, 1, 1, 1 );
        protected static const HEADER_SHADOW_SCALE9_GRID:Rectangle = new Rectangle( 2, 10, 1, 58.5 );
        protected static const INPUT_SCALE9_GRID:Rectangle = new Rectangle( 3, 3, 4, 44 );
        protected static const TOGGLE_SWITCH_TRACK_SCALE9_GRID:Rectangle = new Rectangle( 6.5, 6.5, 22, 1 );
        protected static const TAB_SCALE9_GRID:Rectangle = new Rectangle( 4, 4, 2, 4 );
        protected static const TAB_SELECTION_SKIN_SCALE9_GRID:Rectangle = new Rectangle( 1, 1, 1, 1 );
        protected static const BACKGROUND_POPUP_SCALE9_GRID:Rectangle = new Rectangle( 10, 10, 4, 11 );
        protected static const LIST_ITEM_SCALE9_GRID:Rectangle = new Rectangle( 4, 4, 2, 42 );
        protected static const DROP_DOWN_LIST_BACKGROUND_SCALE9_GRID:Rectangle = new Rectangle( 7, 7, 5, 11 );
        protected static const SPINNER_LIST_OVERLAY_SCALE9_GRID:Rectangle = new Rectangle( 4, 4, 2, 42 );
        protected static const DATE_TIME_SPINNER_BACKGROUND_SCALE9_GRID:Rectangle = new Rectangle( 2, 2, 6, 6 );
        protected static const VERTICAL_SCROLL_BAR_SCALE9_GRID:Rectangle = new Rectangle( 0, 5, 3, 13 );
        protected static const HORIZONTAL_SCROLL_BAR_SCALE9_GRID:Rectangle = new Rectangle( 5, 0, 13, 3 );

        /* Dimensions */
		protected static var mExtraSmallPaddingSize:int;
        protected static var mSmallPaddingSize:int;
        protected static var mRegularPaddingSize:int;
        protected static var mTrackSize:int;
        protected static var mControlSize:int;
        protected static var mSmallerControlSize:int;
        protected static var mLargeControlSize:int;
        protected static var mWideControlSize:int;
        protected static var mHeaderSize:int;
        protected static var mHeaderShadowSize:int;

        /* Fonts */
        protected static var mSmallFontSize:int;
        protected static var mRegularFontSize:int;
        protected static var mLargeFontSize:int;
        protected static var mExtraLargeFontSize:int;

        protected static var mLightRegularTF:TextFormat;
        protected static var mLightRegularDisabledTF:TextFormat;
        protected static var mLightBoldTF:TextFormat;
        protected static var mLightBoldLargeTF:TextFormat;
        protected static var mLightBoldLargeDisabledTF:TextFormat;
        protected static var mLightRegularSmallTF:TextFormat;
        protected static var mLightRegularSmallDisabledTF:TextFormat;
        protected static var mDarkRegularTF:TextFormat;
        protected static var mAccentBoldTF:TextFormat;
        protected static var mAccentBoldExtraLargeTF:TextFormat;
        protected static var mAccentBoldExtraLargeDisabledTF:TextFormat;
        protected static var mAccentRegularTF:TextFormat;
        protected static var mAccentRegularDisabledTF:TextFormat;
        protected static var mTabUpTF:TextFormat;

        /**
         * The texture atlas that contains skins for this theme. This base class
         * does not initialize this member variable. Subclasses are expected to
         * load the assets somehow and set the <code>atlas</code> member
         * variable before calling <code>initialize()</code>.
         */
        protected static var mAtlas:TextureAtlas;


        /* Textures */
        protected static var mButtonAlertQuietDownTexture:Texture;
        protected static var mButtonPrimaryUpTexture:Texture;
        protected static var mButtonPrimaryDownTexture:Texture;
        protected static var mButtonPrimaryDisabledTexture:Texture;
        protected static var mButtonPrimaryQuietDownTexture:Texture;
        protected static var mButtonAccentUpTexture:Texture;
        protected static var mButtonAccentDownTexture:Texture;
        protected static var mButtonAccentDisabledTexture:Texture;
        protected static var mButtonAccentQuietDownTexture:Texture;
        protected static var mButtonBackUpTexture:Texture;
        protected static var mButtonBackDownTexture:Texture;
        protected static var mButtonBackDisabledTexture:Texture;
        protected static var mButtonForwardUpTexture:Texture;
        protected static var mButtonForwardDownTexture:Texture;
        protected static var mButtonForwardDisabledTexture:Texture;
        protected static var mButtonCallToActionPrimaryUpTexture:Texture;
        protected static var mButtonCallToActionPrimaryDownTexture:Texture;
        protected static var mButtonCallToActionPrimaryDisabledTexture:Texture;
        protected static var mButtonCallToActionAccentUpTexture:Texture;
        protected static var mButtonCallToActionAccentDownTexture:Texture;
        protected static var mButtonCallToActionAccentDisabledTexture:Texture;
        protected static var mButtonSelectedUpTexture:Texture;
        protected static var mButtonSelectedDisabledTexture:Texture;
        protected static var mButtonHeaderQuietDownTexture:Texture;
        protected static var mToggleSwitchThumbOnTexture:Texture;
        protected static var mToggleSwitchThumbOffTexture:Texture;
        protected static var mToggleSwitchThumbDisabledTexture:Texture;
        protected static var mSliderHorizontalFillTexture:Texture;
        protected static var mSliderHorizontalBackgroundTexture:Texture;
        protected static var mSliderHorizontalBackgroundDisabledTexture:Texture;
        protected static var mSliderVerticalFillTexture:Texture;
        protected static var mSliderVerticalBackgroundTexture:Texture;
        protected static var mSliderVerticalBackgroundDisabledTexture:Texture;
        protected static var mCheckUpIconTexture:Texture;
        protected static var mCheckSelectedUpIconTexture:Texture;
        protected static var mCheckDownIconTexture:Texture;
        protected static var mCheckDisabledIconTexture:Texture;
        protected static var mCheckSelectedDownIconTexture:Texture;
        protected static var mCheckSelectedDisabledIconTexture:Texture;
        protected static var mRadioUpIconTexture:Texture;
        protected static var mRadioSelectedUpIconTexture:Texture;
        protected static var mRadioDownIconTexture:Texture;
        protected static var mRadioDisabledIconTexture:Texture;
        protected static var mRadioSelectedDownIconTexture:Texture;
        protected static var mRadioSelectedDisabledIconTexture:Texture;
        protected static var mProgressBarFillTexture:Texture;
        protected static var mProgressBarBackgroundTexture:Texture;
        protected static var mProgressBarBackgroundDisabledTexture:Texture;
        protected static var mHeaderBackgroundTexture:Texture;
        protected static var mBackgroundToolbarTexture:Texture;
        protected static var mHeaderShadowBackgroundTexture:Texture;
        protected static var mVerticalScrollBarTexture:Texture;
        protected static var mHorizontalScrollBarTexture:Texture;
        protected static var mTabUpTexture:Texture;
        protected static var mTabDownTexture:Texture;
        protected static var mTabInvertedUpTexture:Texture;
        protected static var mTabInvertedDownTexture:Texture;
        protected static var mTextInputUpTexture:Texture;
        protected static var mTextInputFocusedTexture:Texture;
        protected static var mSearchIconUpTexture:Texture;
        protected static var mSearchIconFocusedTexture:Texture;
        protected static var mBackgroundPopUpTexture:Texture;
        protected static var mBackgroundPlainTexture:Texture;
        protected static var mBackgroundDrawersTexture:Texture;
        protected static var mCalloutUpArrowTexture:Texture;
        protected static var mCalloutRightArrowTexture:Texture;
        protected static var mCalloutDownArrowTexture:Texture;
        protected static var mCalloutLeftArrowTexture:Texture;
        protected static var mToggleSwitchTrackOnTexture:Texture;
        protected static var mToggleSwitchTrackOffTexture:Texture;
        protected static var mToggleSwitchTrackDisabledTexture:Texture;
        protected static var mListItemRendererUpTexture:Texture;
        protected static var mListItemRendererDownTexture:Texture;
        protected static var mListItemRendererSelectedTexture:Texture;
        protected static var mDropDownListItemRendererDownTexture:Texture;
        protected static var mDropDownListItemRendererUpTexture:Texture;
        protected static var mDropDownListItemRendererSelectedTexture:Texture;
        protected static var mGroupedListHeaderTexture:Texture;
        protected static var mPickerListButtonIcon:Texture;
        protected static var mPickerListButtonDisabledIcon:Texture;
        protected static var mDropDownListBackgroundTexture:Texture;
        protected static var mSpinnerListSelectionOverlayTexture:Texture;
        protected static var mDateTimeSpinnerBackgroundTexture:Texture;
        protected static var mPageIndicatorNormalTexture:Texture;
        protected static var mPageIndicatorSelectedTexture:Texture;
        protected static var mTreeDisclosureOpenIconTexture:Texture;
        protected static var mTreeDisclosureClosedIconTexture:Texture;

        /* Media controls */
        protected static var mPlayIconTexture:Texture;
        protected static var mPauseIconTexture:Texture;
        protected static var mVolumeUpIconTexture:Texture;
        protected static var mVolumeDownIconTexture:Texture;
        protected static var mVolumeSliderMinTrackTexture:Texture;
        protected static var mVolumeSliderMaxTrackTexture:Texture;
        protected static var mFullScreenEnterIconTexture:Texture;
        protected static var mFullScreenExitIconTexture:Texture;
        protected static var mSeekSliderFillTexture:Texture;
        protected static var mSeekSliderBackgroundTexture:Texture;

	    /* Public name list */
        public static const THEME_STYLE_NAME_BUTTON_ACCENT:String = "material-deep-grey-amber-mobile-button-accent";
        public static const THEME_STYLE_NAME_BUTTON_ACCENT_QUIET:String = "material-deep-grey-amber-mobile-button-accent-quiet";
        public static const THEME_STYLE_NAME_BUTTON_HEADER_QUIET:String = "material-deep-grey-amber-mobile-button-header-quiet";
        public static const THEME_STYLE_NAME_BUTTON_HEADER_QUIET_ICON_ONLY:String = "material-deep-grey-amber-mobile-button-header-quiet-icon-only";
        public static const THEME_STYLE_NAME_CALL_TO_ACTION_BUTTON_ACCENT:String = "material-deep-grey-amber-mobile-call-to-action-button-accent";
        public static const THEME_STYLE_NAME_PANEL_WITHOUT_PADDING:String = "material-deep-grey-amber-mobile-panel-without-padding";
        public static const THEME_STYLE_NAME_HEADER_WITH_SHADOW:String = "material-deep-grey-amber-mobile-header-with-shadow";
        public static const THEME_STYLE_NAME_TAB_BAR_SHADOW_BOTTOM:String = "material-deep-grey-amber-mobile-tab-bar-shadow-bottom";
        public static const THEME_STYLE_NAME_TAB_BAR_WITH_ICONS:String = "material-deep-grey-amber-mobile-tab-bar-with-icons";
	    public static const THEME_STYLE_NAME_TAB_NAVIGATOR_WITH_ICONS:String = "material-deep-grey-amber-mobile-tab-navigator-with-icons";
	    public static const THEME_STYLE_NAME_TAB_NAVIGATOR_SHADOW_BOTTOM:String = "material-deep-grey-amber-mobile-tab-navigator-shadow-bottom";
	    /* Protected name list */
	    protected static const THEME_STYLE_NAME_TAB_NAVIGATOR_TAB_BAR_WITH_ICONS_SHADOW_BOTTOM:String = "material-deep-grey-amber-mobile-tab-navigator-tab-bar-with-icons-shadow-bottom";
        protected static const THEME_STYLE_NAME_TAB_SHADOW_BOTTOM:String = "material-deep-grey-amber-mobile-tab-shadow-bottom";
        protected static const THEME_STYLE_NAME_TAB_WITH_ICON:String = "material-deep-grey-amber-mobile-tab-with-icon";
        protected static const THEME_STYLE_NAME_TAB_SHADOW_BOTTOM_WITH_ICON:String = "material-deep-grey-amber-mobile-tab-shadow-bottom-with-icon";
        protected static const THEME_STYLE_NAME_VERTICAL_SIMPLE_SCROLL_BAR_THUMB:String = "material-deep-grey-amber-mobile-vertical-simple-scroll-bar-thumb";
        protected static const THEME_STYLE_NAME_HORIZONTAL_SIMPLE_SCROLL_BAR_THUMB:String = "material-deep-grey-amber-mobile-horizontal-simple-scroll-bar-thumb";
        protected static const THEME_STYLE_NAME_HORIZONTAL_SLIDER_MINIMUM_TRACK:String = "material-deep-grey-amber-mobile-horizontal-slider-minimum-track";
        protected static const THEME_STYLE_NAME_HORIZONTAL_SLIDER_MAXIMUM_TRACK:String = "material-deep-grey-amber-mobile-horizontal-slider-maximum-track";
        protected static const THEME_STYLE_NAME_VERTICAL_SLIDER_MINIMUM_TRACK:String = "material-deep-grey-amber-mobile-vertical-slider-minimum-track";
        protected static const THEME_STYLE_NAME_VERTICAL_SLIDER_MAXIMUM_TRACK:String = "material-deep-grey-amber-mobile-vertical-slider-maximum-track";
        protected static const THEME_STYLE_NAME_ALERT_BUTTON_GROUP_BUTTON:String = "material-deep-grey-amber-mobile-alert-button-group-button";
        protected static const THEME_STYLE_NAME_ALERT_HEADER:String = "material-deep-grey-amber-mobile-alert-header";
        protected static const THEME_STYLE_NAME_GROUPED_LIST_LAST_ITEM_RENDERER:String = "material-deep-grey-amber-mobile-grouped-list-last-item-renderer";
        protected static const THEME_STYLE_NAME_GROUPED_LIST_FOOTER_CONTENT_LABEL:String = "material-deep-grey-amber-mobile-grouped-list-footer-content-label";
        protected static const THEME_STYLE_NAME_DROP_DOWN_LIST_ITEM_RENDERER:String = "material-deep-grey-amber-mobile-picker-list-item-renderer";
        protected static const THEME_STYLE_NAME_SPINNER_LIST_ITEM_RENDERER:String = "material-deep-grey-amber-mobile-spinner-list-item-renderer";
        protected static const THEME_STYLE_NAME_DATE_TIME_SPINNER_LIST_ITEM_RENDERER:String = "material-deep-grey-amber-mobile-date-time-spinner-list-item-renderer";
		
		public static var defaultPanelPadding:int;

        public function BaseMaterialDeepGreyAmberMobileTheme() {
            super();
        }

        /**
         *
         *
         * Initializers
         *
         *
         */

        /**
         * Initializes the theme. Expected to be called by subclasses after the
         * assets have been loaded and the skin texture atlas has been created.
         */
        protected function initialize():void {
            initializeDimensions();
            initializeFonts();
            initializeTextures();
            initializeGlobals();
            initializeStage();
            initializeStyleProviders();
        }

        protected function initializeStage():void {
            Starling.current.stage.color = COLOR_BACKGROUND_DARK;
            Starling.current.nativeStage.color = COLOR_BACKGROUND_DARK;
        }

        protected function initializeDimensions():void {
			mExtraSmallPaddingSize = 5;
			mSmallPaddingSize = 10;
			defaultPanelPadding = mSmallPaddingSize;
            mRegularPaddingSize = 20;
            mTrackSize = 4;
            mSmallerControlSize = 37.5;
            mControlSize = 39;
            mLargeControlSize = 50;
            mWideControlSize = 60;
            mHeaderSize = 50;
            mHeaderShadowSize = 78.5;
        }

        protected function initializeTextures():void {
            /* Animation related textures */
            RadialEffectPool.mRadialEffectTexture = mAtlas.getTexture( "radial-effect" );
            LightRadialEffectPool.mRadialEffectTexture =
                    PrimaryRadialEffectPool.mRadialEffectTexture = mAtlas.getTexture( "radial-effect-light" );
            AccentRadialEffectPool.mRadialEffectTexture = mAtlas.getTexture( "radial-effect-accent" );
            ToggleRadialEffectPool.mRadialEffectOnTexture = mAtlas.getTexture( "radial-effect-toggle-on" );
            ToggleRadialEffectPool.mRadialEffectOffTexture = mAtlas.getTexture( "radial-effect-toggle-off" );

            /* Alert */
            mButtonAlertQuietDownTexture = mAtlas.getTexture( "button-alert-quiet-down" );

            /* Background */
            mBackgroundPlainTexture = mAtlas.getTexture( "background-plain" );
            mBackgroundPopUpTexture = mAtlas.getTexture( "background-shadow" );
            mBackgroundToolbarTexture = mAtlas.getTexture( "toolbar-background-translucent" );
            mBackgroundDrawersTexture = mAtlas.getTexture( "background-drawers" );
            mDropDownListBackgroundTexture = mAtlas.getTexture( "picker-list-list-background" );
            mDateTimeSpinnerBackgroundTexture = mAtlas.getTexture( "date-time-spinner-background" );

            /* Button */
            mButtonPrimaryUpTexture = mAtlas.getTexture( "button-primary-up" );
            mButtonPrimaryDownTexture = mAtlas.getTexture( "button-primary-down" );
            mButtonPrimaryDisabledTexture = mAtlas.getTexture( "button-primary-disabled" );
            mButtonPrimaryQuietDownTexture = mAtlas.getTexture( "button-primary-quiet-down" );
            mButtonAccentUpTexture = mAtlas.getTexture( "button-accent-up" );
            mButtonAccentDownTexture = mAtlas.getTexture( "button-accent-down" );
            mButtonAccentDisabledTexture = mAtlas.getTexture( "button-accent-disabled" );
            mButtonAccentQuietDownTexture = mAtlas.getTexture( "button-accent-quiet-down" );
            mButtonSelectedUpTexture = mAtlas.getTexture( "button-selected-up" );
            mButtonSelectedDisabledTexture = mAtlas.getTexture( "button-selected-disabled" );
            mButtonHeaderQuietDownTexture = mAtlas.getTexture( "button-header-quiet-down" );

            mButtonCallToActionPrimaryUpTexture = mAtlas.getTexture( "button-call-to-action-primary-up" );
            mButtonCallToActionPrimaryDownTexture = mAtlas.getTexture( "button-call-to-action-primary-down" );
            mButtonCallToActionPrimaryDisabledTexture = mAtlas.getTexture( "button-call-to-action-primary-disabled" );
            mButtonCallToActionAccentUpTexture = mAtlas.getTexture( "button-call-to-action-accent-up" );
            mButtonCallToActionAccentDownTexture = mAtlas.getTexture( "button-call-to-action-accent-down" );
            mButtonCallToActionAccentDisabledTexture = mAtlas.getTexture( "button-call-to-action-accent-disabled" );

            mButtonBackUpTexture = mAtlas.getTexture( "button-back-up" );
            mButtonBackDownTexture = mAtlas.getTexture( "button-back-down" );
            mButtonBackDisabledTexture = mAtlas.getTexture( "button-back-disabled" );
            mButtonForwardUpTexture = mAtlas.getTexture( "button-forward-up" );
            mButtonForwardDownTexture = mAtlas.getTexture( "button-forward-down" );
            mButtonForwardDisabledTexture = mAtlas.getTexture( "button-forward-disabled" );

            /* Callout */
            mCalloutUpArrowTexture = mAtlas.getTexture( "callout-arrow-up" );
            mCalloutRightArrowTexture = mAtlas.getTexture( "callout-arrow-right" );
            mCalloutDownArrowTexture = mAtlas.getTexture( "callout-arrow-down" );
            mCalloutLeftArrowTexture = mAtlas.getTexture( "callout-arrow-left" );

            /* Check */
            mCheckUpIconTexture = mAtlas.getTexture( "check-up-icon" );
            mCheckDownIconTexture = mAtlas.getTexture( "check-down-icon" );
            mCheckDisabledIconTexture = mAtlas.getTexture( "check-disabled-icon" );
            mCheckSelectedUpIconTexture = mAtlas.getTexture( "check-selected-up-icon" );
            mCheckSelectedDownIconTexture = mAtlas.getTexture( "check-selected-down-icon" );
            mCheckSelectedDisabledIconTexture = mAtlas.getTexture( "check-selected-disabled-icon" );

            /* Dropdown List */
            mDropDownListItemRendererUpTexture = mAtlas.getTexture( "list-drop-down-item-up" );
            mDropDownListItemRendererDownTexture = mAtlas.getTexture( "list-drop-down-item-down" );
            mDropDownListItemRendererSelectedTexture = mAtlas.getTexture( "list-drop-down-item-selected" );

            /* Header */
            mHeaderBackgroundTexture = mAtlas.getTexture( "background-header" );
            mHeaderShadowBackgroundTexture = mAtlas.getTexture( "background-header-shadow" );

            /* List / GroupedList / Item renderers */
            mListItemRendererUpTexture = mAtlas.getTexture( "list-item-up" );
            mListItemRendererDownTexture = mAtlas.getTexture( "list-item-down" );
            mListItemRendererSelectedTexture = mAtlas.getTexture( "list-item-selected" );
            mGroupedListHeaderTexture = mAtlas.getTexture( "grouped-list-header" );

            /* Page indicator */
            mPageIndicatorNormalTexture = mAtlas.getTexture( "toggle-switch-thumb-off" );
            mPageIndicatorSelectedTexture = mAtlas.getTexture( "toggle-switch-thumb-on" );
            PageIndicatorRadialAnimationManager.mSelectedSymbolTexture = mPageIndicatorSelectedTexture;

            /* Picker list */
            mPickerListButtonIcon = mAtlas.getTexture( "picker-list-button-icon" );
            mPickerListButtonDisabledIcon = mAtlas.getTexture( "picker-list-button-disabled-icon" );

            /* ProgressBar */
            mProgressBarFillTexture = mAtlas.getTexture( "progress-bar-fill" );
            mProgressBarBackgroundTexture = mAtlas.getTexture( "progress-bar-background" );
            mProgressBarBackgroundDisabledTexture = mAtlas.getTexture( "progress-bar-background-disabled" );

            /* Slider */
            mSliderHorizontalFillTexture = mAtlas.getTexture( "slider-fill-horizontal" );
            mSliderHorizontalBackgroundTexture = mAtlas.getTexture( "slider-background-horizontal" );
            mSliderHorizontalBackgroundDisabledTexture = mAtlas.getTexture( "slider-background-disabled-horizontal" );
            mSliderVerticalFillTexture = mAtlas.getTexture( "slider-fill-vertical" );
            mSliderVerticalBackgroundTexture = mAtlas.getTexture( "slider-background-vertical" );
            mSliderVerticalBackgroundDisabledTexture = mAtlas.getTexture( "slider-background-disabled-vertical" );

            AnimatedSliderThumb.mUpTexture = mAtlas.getTexture( "slider-thumb-up" );
            AnimatedSliderThumb.mDownTexture = mAtlas.getTexture( "slider-thumb-down" );
            AnimatedSliderThumb.mDisabledTexture = mAtlas.getTexture( "slider-thumb-disabled" );
            AnimatedSliderThumb.mThumbScale9Grid = SLIDER_THUMB_SCALE9_GRID;

            /* Radio */
            mRadioUpIconTexture = mAtlas.getTexture( "radio-up-icon" );
            mRadioDownIconTexture = mAtlas.getTexture( "radio-down-icon" );
            mRadioDisabledIconTexture = mAtlas.getTexture( "radio-disabled-icon" );
            mRadioSelectedUpIconTexture = mAtlas.getTexture( "radio-selected-up-icon" );
            mRadioSelectedDownIconTexture = mAtlas.getTexture( "radio-selected-down-icon" );
            mRadioSelectedDisabledIconTexture = mAtlas.getTexture( "radio-selected-disabled-icon" );

            /* Scroll bar */
            mVerticalScrollBarTexture = mAtlas.getTexture( "scroll-bar-vertical" );
            mHorizontalScrollBarTexture = mAtlas.getTexture( "scroll-bar-horizontal" );

            /* Spinner list */
            mSpinnerListSelectionOverlayTexture = mAtlas.getTexture( "spinner-list-selection-overlay" );

            /* TabBar */
            mTabUpTexture = mAtlas.getTexture( "tab-up" );
            mTabDownTexture = mAtlas.getTexture( "tab-down" );
            mTabInvertedUpTexture = mAtlas.getTexture( "tab-inverted-up" );
            mTabInvertedDownTexture = mAtlas.getTexture( "tab-inverted-down" );

            /* Text & search inputs */
            mTextInputUpTexture = mAtlas.getTexture( "text-input-up" );
            mTextInputFocusedTexture = mAtlas.getTexture( "text-input-focused" );
            mSearchIconUpTexture = mAtlas.getTexture( "search-input-icon-up" );
            mSearchIconFocusedTexture = mAtlas.getTexture( "search-input-icon-focused" );

            /* ToggleSwitch */
            mToggleSwitchTrackOnTexture = mAtlas.getTexture( "toggle-switch-track-on" );
            mToggleSwitchTrackOffTexture = mAtlas.getTexture( "toggle-switch-track-off" );
            mToggleSwitchTrackDisabledTexture = mAtlas.getTexture( "toggle-switch-track-disabled" );

            mToggleSwitchThumbOnTexture = mAtlas.getTexture( "toggle-switch-thumb-on" );
            mToggleSwitchThumbOffTexture = mAtlas.getTexture( "toggle-switch-thumb-off" );
            mToggleSwitchThumbDisabledTexture = mAtlas.getTexture( "toggle-switch-thumb-disabled" );

            /* Tree */
            mTreeDisclosureOpenIconTexture = mAtlas.getTexture( "tree-disclosure-open-icon" );
            mTreeDisclosureClosedIconTexture = mAtlas.getTexture( "tree-disclosure-closed-icon" );

            /* Media controls */
            mPlayIconTexture = mAtlas.getTexture( "play-button-icon" );
            mPauseIconTexture = mAtlas.getTexture( "pause-button-icon" );
            mFullScreenEnterIconTexture = mAtlas.getTexture( "full-screen-enter-icon" );
            mFullScreenExitIconTexture = mAtlas.getTexture( "full-screen-exit-icon" );
            mVolumeUpIconTexture = mAtlas.getTexture( "volume-up-icon" );
            mVolumeDownIconTexture = mAtlas.getTexture( "volume-down-icon" );
            mVolumeSliderMinTrackTexture = mAtlas.getTexture( "volume-slider-min-track" );
            mVolumeSliderMaxTrackTexture = mAtlas.getTexture( "volume-slider-max-track" );
            AnimatedSeekSliderThumb.mUpTexture = mAtlas.getTexture( "seek-slider-thumb-up" );
            AnimatedSeekSliderThumb.mDownTexture = mAtlas.getTexture( "seek-slider-thumb-down" );
            AnimatedSeekSliderThumb.mDisabledTexture = mAtlas.getTexture( "seek-slider-thumb-down" );
            mSeekSliderFillTexture = mAtlas.getTexture( "seek-slider-fill" );
            mSeekSliderBackgroundTexture = mAtlas.getTexture( "seek-slider-background" );
        }

        protected function initializeFonts():void {
            mSmallFontSize = 10;
            mRegularFontSize = 14;
            mLargeFontSize = 20;
            mExtraLargeFontSize = 25;

            /* UI */
            mLightRegularTF = getTextFormat( mRegularFontSize, COLOR_UI_LIGHT );
            mLightRegularDisabledTF = getTextFormat( mRegularFontSize, COLOR_UI_LIGHT_DISABLED );
            mLightRegularSmallTF = getTextFormat( mSmallFontSize, COLOR_UI_LIGHT );
            mLightRegularSmallDisabledTF = getTextFormat( mSmallFontSize, COLOR_UI_LIGHT_DISABLED );
            mLightBoldTF = getTextFormat( mRegularFontSize, COLOR_UI_EXTRA_LIGHT, true );
            mLightBoldLargeTF = getTextFormat( mLargeFontSize, COLOR_UI_EXTRA_LIGHT, true );
            mLightBoldLargeDisabledTF = getTextFormat( mLargeFontSize, COLOR_UI_LIGHT_DISABLED, true );
            mDarkRegularTF = getTextFormat( mRegularFontSize, COLOR_UI_DARK );
            mAccentBoldTF = getTextFormat( 16, 0xEEEEEE, true );
            mAccentBoldExtraLargeTF = getTextFormat( mExtraLargeFontSize, COLOR_ACCENT, true );
            mAccentBoldExtraLargeDisabledTF = getTextFormat( mExtraLargeFontSize, COLOR_ACCENT, true );
            mAccentRegularTF = getTextFormat( mRegularFontSize, COLOR_ACCENT );
            mAccentRegularDisabledTF = getTextFormat( mRegularFontSize, COLOR_ACCENT_DARK_50 );
            mTabUpTF = getTextFormat( mRegularFontSize, 0x949599 );
        }

        protected function initializeGlobals():void {
            FeathersControl.defaultTextEditorFactory = textEditorFactory;
            FeathersControl.defaultTextRendererFactory = textRendererFactory;

            PopUpManager.overlayFactory = popUpOverlayFactory;
        }

	    protected function initializeStyleProviders():void {
		    /* Alert */
		    getStyleProviderForClass( Alert ).defaultStyleFunction = setAlertStyles;
		    getStyleProviderForClass( ButtonGroup ).setFunctionForStyleName( Alert.DEFAULT_CHILD_STYLE_NAME_BUTTON_GROUP, setAlertButtonGroupStyles );
		    getStyleProviderForClass( Button ).setFunctionForStyleName( THEME_STYLE_NAME_ALERT_BUTTON_GROUP_BUTTON, setAlertButtonGroupButtonStyles );
		    getStyleProviderForClass( Header ).setFunctionForStyleName( THEME_STYLE_NAME_ALERT_HEADER, setAlertHeaderStyles );

		    /* AutoComplete */
		    getStyleProviderForClass( AutoComplete ).defaultStyleFunction = setTextInputStyles;
		    getStyleProviderForClass( AutoComplete ).setFunctionForStyleName( TextInput.ALTERNATE_STYLE_NAME_SEARCH_TEXT_INPUT, setSearchTextInputStyles );
		    getStyleProviderForClass( List ).setFunctionForStyleName( AutoComplete.DEFAULT_CHILD_STYLE_NAME_LIST, setAutoCompleteListStyles );

		    /* Buttons */
		    getStyleProviderForClass( Button ).defaultStyleFunction = setButtonStyles;
		    getStyleProviderForClass( Button ).setFunctionForStyleName( Button.ALTERNATE_STYLE_NAME_QUIET_BUTTON, setPrimaryQuietButtonStyles );
		    getStyleProviderForClass( Button ).setFunctionForStyleName( THEME_STYLE_NAME_BUTTON_ACCENT_QUIET, setAccentQuietButtonStyles );
		    getStyleProviderForClass( Button ).setFunctionForStyleName( THEME_STYLE_NAME_BUTTON_HEADER_QUIET, setHeaderQuietButtonStyles );
		    getStyleProviderForClass( Button ).setFunctionForStyleName( THEME_STYLE_NAME_BUTTON_HEADER_QUIET_ICON_ONLY, setHeaderQuietButtonIconOnlyStyles );
		    getStyleProviderForClass( Button ).setFunctionForStyleName( THEME_STYLE_NAME_BUTTON_ACCENT, setAccentButtonStyles );
		    getStyleProviderForClass( Button ).setFunctionForStyleName( THEME_STYLE_NAME_CALL_TO_ACTION_BUTTON_ACCENT, setCallToActionAccentButtonStyles );
		    getStyleProviderForClass( Button ).setFunctionForStyleName( Button.ALTERNATE_STYLE_NAME_CALL_TO_ACTION_BUTTON, setCallToActionPrimaryButtonStyles );
		    getStyleProviderForClass( Button ).setFunctionForStyleName( Button.ALTERNATE_STYLE_NAME_BACK_BUTTON, setBackButtonStyles );
		    getStyleProviderForClass( Button ).setFunctionForStyleName( Button.ALTERNATE_STYLE_NAME_FORWARD_BUTTON, setForwardButtonStyles );
		    getStyleProviderForClass( ToggleButton ).defaultStyleFunction = setButtonStyles;
		    getStyleProviderForClass( ToggleButton ).setFunctionForStyleName( Button.ALTERNATE_STYLE_NAME_QUIET_BUTTON, setPrimaryQuietButtonStyles );
		    getStyleProviderForClass( ToggleButton ).setFunctionForStyleName( THEME_STYLE_NAME_BUTTON_ACCENT_QUIET, setAccentQuietButtonStyles );

		    /* ButtonGroup */
		    getStyleProviderForClass( ButtonGroup ).defaultStyleFunction = setButtonGroupStyles;
		    getStyleProviderForClass( Button ).setFunctionForStyleName( ButtonGroup.DEFAULT_CHILD_STYLE_NAME_BUTTON, setButtonStyles );
		    getStyleProviderForClass( ToggleButton ).setFunctionForStyleName( ButtonGroup.DEFAULT_CHILD_STYLE_NAME_BUTTON, setButtonStyles );

		    /* Callout */
		    getStyleProviderForClass( Callout ).defaultStyleFunction = setCalloutStyles;

		    /* Check */
		    getStyleProviderForClass( Check ).defaultStyleFunction = setCheckStyles;

		    /* DateTimeSpinner */
		    getStyleProviderForClass( DateTimeSpinner ).defaultStyleFunction = setDateTimeSpinnerStyles;
            getStyleProviderForClass( SpinnerList ).setFunctionForStyleName( DateTimeSpinner.DEFAULT_CHILD_STYLE_NAME_LIST, setDateTimeSpinnerListStyles );
            getStyleProviderForClass( DefaultListItemRenderer ).setFunctionForStyleName( THEME_STYLE_NAME_DATE_TIME_SPINNER_LIST_ITEM_RENDERER, setDateTimeSpinnerListItemRendererStyles );

		    /* Drawers */
		    getStyleProviderForClass( Drawers ).defaultStyleFunction = setDrawersStyles;

		    /* GroupedList*/
		    getStyleProviderForClass( GroupedList ).defaultStyleFunction = setGroupedListStyles;

		    /* Header */
		    getStyleProviderForClass( Header ).defaultStyleFunction = setHeaderStyles;

		    /* Label */
		    getStyleProviderForClass( Label ).defaultStyleFunction = setLabelStyles;
		    getStyleProviderForClass( Label ).setFunctionForStyleName( Label.ALTERNATE_STYLE_NAME_HEADING, setHeadingLabelStyles );
		    getStyleProviderForClass( Label ).setFunctionForStyleName( Label.ALTERNATE_STYLE_NAME_DETAIL, setDetailLabelStyles );

		    /* LayoutGroup */
		    getStyleProviderForClass( LayoutGroup ).setFunctionForStyleName( LayoutGroup.ALTERNATE_STYLE_NAME_TOOLBAR, setLayoutGroupToolbarStyles );

		    /* List / Item renderers */
		    getStyleProviderForClass( List ).defaultStyleFunction = setListStyles;
		    getStyleProviderForClass( DefaultListItemRenderer ).defaultStyleFunction = setItemRendererStyles;
		    getStyleProviderForClass( DefaultGroupedListItemRenderer ).defaultStyleFunction = setItemRendererStyles;
		    getStyleProviderForClass( DefaultListItemRenderer ).setFunctionForStyleName( THEME_STYLE_NAME_DROP_DOWN_LIST_ITEM_RENDERER, setPickerListItemRendererStyles );

		    /* GroupedList header / footer */
		    getStyleProviderForClass( DefaultGroupedListHeaderOrFooterRenderer ).defaultStyleFunction = setGroupedListHeaderRendererStyles;
		    getStyleProviderForClass( DefaultGroupedListHeaderOrFooterRenderer ).setFunctionForStyleName( GroupedList.DEFAULT_CHILD_STYLE_NAME_FOOTER_RENDERER, setGroupedListFooterRendererStyles );

		    /* Numeric stepper */
		    getStyleProviderForClass( NumericStepper ).defaultStyleFunction = setNumericStepperStyles;
		    getStyleProviderForClass( TextInput ).setFunctionForStyleName( NumericStepper.DEFAULT_CHILD_STYLE_NAME_TEXT_INPUT, setNumericStepperTextInputStyles );
		    getStyleProviderForClass( Button ).setFunctionForStyleName( NumericStepper.DEFAULT_CHILD_STYLE_NAME_DECREMENT_BUTTON, setNumericStepperButtonStyles );
		    getStyleProviderForClass( Button ).setFunctionForStyleName( NumericStepper.DEFAULT_CHILD_STYLE_NAME_INCREMENT_BUTTON, setNumericStepperButtonStyles );

		    /* Page indicator */
		    getStyleProviderForClass( PageIndicator ).defaultStyleFunction = setPageIndicatorStyles;

		    /* Panel */
		    getStyleProviderForClass( Panel ).defaultStyleFunction = setPanelWithPaddingStyles;
            getStyleProviderForClass( Panel ).setFunctionForStyleName( THEME_STYLE_NAME_HEADER_WITH_SHADOW, setPanelWithShadowStyles );
		    getStyleProviderForClass( Panel ).setFunctionForStyleName( THEME_STYLE_NAME_PANEL_WITHOUT_PADDING, setBasePanelStyles );
		    getStyleProviderForClass( Header ).setFunctionForStyleName( Panel.DEFAULT_CHILD_STYLE_NAME_HEADER, setHeaderWithoutBackgroundStyles );

		    /* Panel screen */
		    getStyleProviderForClass( PanelScreen ).defaultStyleFunction = setPanelWithPaddingStyles;
		    getStyleProviderForClass( PanelScreen ).setFunctionForStyleName( THEME_STYLE_NAME_PANEL_WITHOUT_PADDING, setBasePanelStyles );
		    getStyleProviderForClass( PanelScreen ).setFunctionForStyleName( THEME_STYLE_NAME_HEADER_WITH_SHADOW, setPanelWithShadowStyles );
		    getStyleProviderForClass( Header ).setFunctionForStyleName( PanelScreen.DEFAULT_CHILD_STYLE_NAME_HEADER, setPanelScreenHeaderStyles );
		    getStyleProviderForClass( Header ).setFunctionForStyleName( THEME_STYLE_NAME_HEADER_WITH_SHADOW, setPanelScreenHeaderWithShadowStyles );

		    /* Picker list */
		    getStyleProviderForClass( List ).setFunctionForStyleName( PickerList.DEFAULT_CHILD_STYLE_NAME_LIST, setPickerListListStyles );
		    getStyleProviderForClass( PickerList ).defaultStyleFunction = setPickerListStyles;
		    getStyleProviderForClass( Button ).setFunctionForStyleName( PickerList.DEFAULT_CHILD_STYLE_NAME_BUTTON, setPickerListButtonStyles );

		    /* Progress bar */
		    getStyleProviderForClass( ProgressBar ).defaultStyleFunction = setProgressBarStyles;

		    /* Radio */
		    getStyleProviderForClass( Radio ).defaultStyleFunction = setRadioStyles;

		    /* Scroll container */
		    getStyleProviderForClass( ScrollContainer ).defaultStyleFunction = setScrollContainerStyles;
		    getStyleProviderForClass( ScrollContainer ).setFunctionForStyleName( ScrollContainer.ALTERNATE_STYLE_NAME_TOOLBAR, setToolbarScrollContainerStyles );

		    /* Scroll text */
		    getStyleProviderForClass( ScrollText ).defaultStyleFunction = setScrollTextStyles;

		    /* Simple scroll bar */
		    getStyleProviderForClass( SimpleScrollBar ).defaultStyleFunction = setSimpleScrollBarStyles;
		    getStyleProviderForClass( Button ).setFunctionForStyleName( THEME_STYLE_NAME_VERTICAL_SIMPLE_SCROLL_BAR_THUMB, setVerticalSimpleScrollBarThumbStyles );
		    getStyleProviderForClass( Button ).setFunctionForStyleName( THEME_STYLE_NAME_HORIZONTAL_SIMPLE_SCROLL_BAR_THUMB, setHorizontalSimpleScrollBarThumbStyles );

		    /* Slider */
		    getStyleProviderForClass( Slider ).defaultStyleFunction = setSliderStyles;
		    getStyleProviderForClass( Button ).setFunctionForStyleName( Slider.DEFAULT_CHILD_STYLE_NAME_THUMB, setSliderThumbStyles );
		    getStyleProviderForClass( Button ).setFunctionForStyleName( THEME_STYLE_NAME_HORIZONTAL_SLIDER_MINIMUM_TRACK, setHorizontalSliderMinimumTrackStyles );
		    getStyleProviderForClass( Button ).setFunctionForStyleName( THEME_STYLE_NAME_HORIZONTAL_SLIDER_MAXIMUM_TRACK, setHorizontalSliderMaximumTrackStyles );
		    getStyleProviderForClass( Button ).setFunctionForStyleName( THEME_STYLE_NAME_VERTICAL_SLIDER_MINIMUM_TRACK, setVerticalSliderMinimumTrackStyles );
		    getStyleProviderForClass( Button ).setFunctionForStyleName( THEME_STYLE_NAME_VERTICAL_SLIDER_MAXIMUM_TRACK, setVerticalSliderMaximumTrackStyles );

		    /* Spinner list */
		    getStyleProviderForClass( SpinnerList ).defaultStyleFunction = setSpinnerListStyles;
		    getStyleProviderForClass( DefaultListItemRenderer ).setFunctionForStyleName( THEME_STYLE_NAME_SPINNER_LIST_ITEM_RENDERER, setSpinnerListItemRendererStyles );

		    /* Tab bar */
		    getStyleProviderForClass( TabBar ).defaultStyleFunction = setTabBarStyles;
		    getStyleProviderForClass( ToggleButton ).setFunctionForStyleName( TabBar.DEFAULT_CHILD_STYLE_NAME_TAB, setTabStyles );
		    getStyleProviderForClass( TabBar ).setFunctionForStyleName( THEME_STYLE_NAME_TAB_BAR_SHADOW_BOTTOM, setInvertedTabBarStyles );
		    getStyleProviderForClass( TabBar ).setFunctionForStyleName( THEME_STYLE_NAME_TAB_BAR_WITH_ICONS, setTabBarWithIconsStyles );
		    getStyleProviderForClass( ToggleButton ).setFunctionForStyleName( THEME_STYLE_NAME_TAB_SHADOW_BOTTOM, setInvertedTabStyles );
		    getStyleProviderForClass( ToggleButton ).setFunctionForStyleName( THEME_STYLE_NAME_TAB_WITH_ICON, setTabWithIconStyles );
		    getStyleProviderForClass( ToggleButton ).setFunctionForStyleName( THEME_STYLE_NAME_TAB_SHADOW_BOTTOM_WITH_ICON, setInvertedTabWithIconStyles );

		    /* Tab navigator */
		    getStyleProviderForClass( TabNavigator ).setFunctionForStyleName( THEME_STYLE_NAME_TAB_NAVIGATOR_WITH_ICONS, setTabNavigatorWithIconsStyles );
		    getStyleProviderForClass( TabNavigator ).setFunctionForStyleName( THEME_STYLE_NAME_TAB_NAVIGATOR_SHADOW_BOTTOM, setInvertedTabNavigatorStyles );
		    getStyleProviderForClass( TabBar ).setFunctionForStyleName( THEME_STYLE_NAME_TAB_NAVIGATOR_TAB_BAR_WITH_ICONS_SHADOW_BOTTOM, setCombinedNavigatorTabBarStyles );

		    /* Text input */
		    getStyleProviderForClass( TextInput ).defaultStyleFunction = setTextInputStyles;
		    getStyleProviderForClass( TextInput ).setFunctionForStyleName( TextInput.ALTERNATE_STYLE_NAME_SEARCH_TEXT_INPUT, setSearchTextInputStyles );

		    /* Text area */
		    getStyleProviderForClass( TextArea ).defaultStyleFunction = setTextAreaStyles;

		    /* Text callout */
		    getStyleProviderForClass( TextCallout ).defaultStyleFunction = setTextCalloutStyles;

		    /* Toggle switch */
		    getStyleProviderForClass( Button ).setFunctionForStyleName( ToggleSwitch.DEFAULT_CHILD_STYLE_NAME_ON_TRACK, setToggleSwitchOnTrackStyles );
		    getStyleProviderForClass( Button ).setFunctionForStyleName( ToggleSwitch.DEFAULT_CHILD_STYLE_NAME_OFF_TRACK, setToggleSwitchOffTrackStyles );
		    getStyleProviderForClass( Button ).setFunctionForStyleName( ToggleSwitch.DEFAULT_CHILD_STYLE_NAME_THUMB, setToggleSwitchThumbStyles );
		    getStyleProviderForClass( ToggleButton ).setFunctionForStyleName( ToggleSwitch.DEFAULT_CHILD_STYLE_NAME_THUMB, setToggleSwitchThumbStyles );
		    getStyleProviderForClass( ToggleSwitch ).defaultStyleFunction = setToggleSwitchStyles;

            /* Tree */
            getStyleProviderForClass( Tree ).defaultStyleFunction = setTreeStyles;
            getStyleProviderForClass( DefaultTreeItemRenderer ).defaultStyleFunction = setTreeItemRendererStyles;

		    /**
		     * Media controls
		     */

		    /* Seek slider */
		    getStyleProviderForClass( SeekSlider ).defaultStyleFunction = setSeekSliderStyles;
		    getStyleProviderForClass( Button ).setFunctionForStyleName( SeekSlider.DEFAULT_CHILD_STYLE_NAME_THUMB, setSeekSliderThumbStyles );
		    getStyleProviderForClass( Button ).setFunctionForStyleName( SeekSlider.DEFAULT_CHILD_STYLE_NAME_MINIMUM_TRACK, setSeekSliderMinimumTrackStyles );
		    getStyleProviderForClass( Button ).setFunctionForStyleName( SeekSlider.DEFAULT_CHILD_STYLE_NAME_MAXIMUM_TRACK, setSeekSliderMaximumTrackStyles );

		    /* Play pause button */
		    getStyleProviderForClass( PlayPauseToggleButton ).defaultStyleFunction = setPlayPauseToggleButtonStyles;

		    /* Mute button */
		    getStyleProviderForClass( MuteToggleButton ).defaultStyleFunction = setMuteToggleButtonStyles;

		    /* Volume slider */
		    getStyleProviderForClass( VolumeSlider ).defaultStyleFunction = setVolumeSliderStyles;
		    getStyleProviderForClass( Button ).setFunctionForStyleName( VolumeSlider.DEFAULT_CHILD_STYLE_NAME_THUMB, setVolumeSliderThumbStyles );
		    getStyleProviderForClass( Button ).setFunctionForStyleName( VolumeSlider.DEFAULT_CHILD_STYLE_NAME_MINIMUM_TRACK, setVolumeSliderMinimumTrackStyles );
		    getStyleProviderForClass( Button ).setFunctionForStyleName( VolumeSlider.DEFAULT_CHILD_STYLE_NAME_MAXIMUM_TRACK, setVolumeSliderMaximumTrackStyles );

		    /* Full screen button */
		    getStyleProviderForClass( FullScreenToggleButton ).defaultStyleFunction = setFullScreenToggleButtonStyles;

		    /* Time label */
		    getStyleProviderForClass( TimeLabel ).defaultStyleFunction = setTimeLabelStyles;
	    }

	    protected function getTextFormat( size:int, color:uint, isBold:Boolean = false, horizontalAlign:String = Align.LEFT, verticalAlign:String = Align.TOP ):TextFormat {
		    var format:TextFormat = new TextFormat( FONT_NAME, size, color, horizontalAlign, verticalAlign );
		    format.bold = isBold;
		    return format;
	    }

        /**
         *
         *
         * Styles
         *
         *
         */

        /**
         * Alert
         */

        protected function setAlertStyles( alert:Alert ):void {
            setScrollerStyles( alert );

            const backgroundSkin:Image = new Image( mBackgroundPopUpTexture );
            backgroundSkin.scale9Grid = BACKGROUND_POPUP_SCALE9_GRID;
            alert.backgroundSkin = backgroundSkin;
            alert.customHeaderStyleName = THEME_STYLE_NAME_ALERT_HEADER;
            alert.padding = alert.gap = mRegularPaddingSize;
            alert.maxWidth = 300;
            alert.maxHeight = 300;

            var format:TextFormat = new TextFormat();
            format.copyFrom( mLightRegularTF );
            format.leading = mRegularFontSize * 0.8;
            alert.fontStyles = format;
        }

        protected function setAlertButtonGroupStyles( group:ButtonGroup ):void {
            group.direction = Direction.HORIZONTAL;
            group.horizontalAlign = HorizontalAlign.RIGHT;
            group.verticalAlign = VerticalAlign.JUSTIFY;
            group.distributeButtonSizes = false;
            group.gap = mSmallPaddingSize >> 1;
            group.padding = mRegularPaddingSize;
            group.paddingTop = 0;
            group.customButtonStyleName = THEME_STYLE_NAME_ALERT_BUTTON_GROUP_BUTTON;
        }

        protected function setAlertButtonGroupButtonStyles( button:Button ):void {
            setPrimaryQuietButtonStyles( button );

            var skin:FadeImageSkin = FadeImageSkin( button.defaultSkin );
            skin.setTextureForState( ButtonState.DOWN, mButtonAlertQuietDownTexture );
            skin.minHeight = mControlSize;

            button.defaultSkin.height = mControlSize;
            button.paddingTop = 12.5;
            button.paddingBottom = 7.5;
            button.paddingLeft = button.paddingRight = mSmallPaddingSize;
        }

        protected function setAlertHeaderStyles( header:Header ):void {
            setHeaderWithoutBackgroundStyles( header );

            header.paddingTop = mRegularPaddingSize;
        }

        /**
         * Auto complete
         */

        protected function setAutoCompleteListStyles( list:List ):void {
            setScrollerStyles( list );

            list.maxHeight = 250;
            list.paddingLeft = 5;
            list.paddingTop = 3.5;
            list.paddingRight = 4.5;
            list.paddingBottom = 5;
            const backgroundSkin:Image = new Image( mDropDownListBackgroundTexture );
            backgroundSkin.scale9Grid = DROP_DOWN_LIST_BACKGROUND_SCALE9_GRID;
            list.backgroundSkin = backgroundSkin;
            list.verticalScrollPolicy = ScrollPolicy.ON;
            list.customItemRendererStyleName = THEME_STYLE_NAME_DROP_DOWN_LIST_ITEM_RENDERER;
        }

        /**
         * Buttons
         */

        protected function setButtonStyles( button:Button ):void {
            var skin:FadeImageSkin = new FadeImageSkin( mButtonPrimaryUpTexture );
            skin.setTextureForState( ButtonState.DOWN, mButtonPrimaryDownTexture );
            skin.setTextureForState( ButtonState.DISABLED, mButtonPrimaryDisabledTexture );
            skin.width = skin.height = mControlSize;
            /* Set ToggleButton styles as well */
            if( button is ToggleButton ) {
                skin.selectedTexture = mButtonSelectedUpTexture;
                skin.setTextureForState( ButtonState.DISABLED_AND_SELECTED, mButtonSelectedDisabledTexture );
            }
            skin.scale9Grid = BUTTON_SCALE9_GRID;
            button.defaultSkin = skin;

            setBaseButtonStyles( button );

            ButtonRadialAnimationManager.getInstance().add( button );
        }

        protected function setPrimaryQuietButtonStyles( button:Button ):void {
            setBaseButtonStyles( button );

            var skin:FadeImageSkin = new FadeImageSkin(null);
            skin.setTextureForState( ButtonState.DOWN, mButtonPrimaryQuietDownTexture );
            skin.scale9Grid = BUTTON_QUIET_SCALE9_GRID;
            skin.minWidth = skin.minHeight = mSmallerControlSize;
            skin.width = skin.height = mSmallerControlSize;

            button.defaultSkin = skin;
            button.paddingTop = 4;

            tintButtonIcon( button, COLOR_UI_LIGHT );

            PrimaryQuietButtonRadialAnimationManager.getInstance().add( button );
        }

        protected function setAccentQuietButtonStyles( button:Button ):void {
            setBaseButtonStyles( button );

            var skin:FadeImageSkin = new FadeImageSkin(null);
            skin.setTextureForState( ButtonState.DOWN, mButtonAccentQuietDownTexture );
            skin.scale9Grid = BUTTON_QUIET_SCALE9_GRID;
            skin.minWidth = skin.minHeight = mSmallerControlSize;
            skin.width = skin.height = mSmallerControlSize;

            button.defaultSkin = skin;
            button.paddingTop = 4;

            tintButtonIcon( button, COLOR_ACCENT );

	        button.fontStyles = mAccentRegularTF.clone();
	        button.disabledFontStyles = mAccentRegularDisabledTF.clone();

            AccentQuietButtonRadialAnimationManager.getInstance().add( button );
        }

        protected function setHeaderQuietButtonStyles( button:Button ):void {
            setBaseButtonStyles( button );

            var skin:FadeImageSkin = new FadeImageSkin(null);
            skin.setTextureForState( ButtonState.DOWN, mButtonHeaderQuietDownTexture );
            skin.scale9Grid = BUTTON_QUIET_SCALE9_GRID;
            skin.minHeight = mSmallerControlSize;
            skin.fadeOutTransition = Transitions.EASE_OUT;

            button.defaultSkin = skin;
            button.paddingTop = 4;

            QuietButtonRadialAnimationManager.getInstance().add( button );
        }

        protected function setHeaderQuietButtonIconOnlyStyles( button:Button ):void {
            var isMediaButton:Boolean = button is ToggleButton;
            setBaseButtonStyles( button, isMediaButton ? 0.75 : 1 );

            var skin:FadeImageSkin = new FadeImageSkin(null);
            skin.setTextureForState( ButtonState.DOWN, mAtlas.getTexture( "radial-effect-light" ) );
            skin.setTextureForState( ButtonState.DOWN_AND_SELECTED, mAtlas.getTexture( "radial-effect-light" ) );
            skin.minHeight = skin.minWidth = 48;
            skin.fadeOutTransition = Transitions.EASE_OUT;

            button.defaultSkin = skin;
            button.paddingTop = 0;
            /* Use small padding for icon-only button */
            button.paddingLeft = button.paddingRight = mSmallPaddingSize;
            button.hasLabelTextRenderer = false;

            HeaderIconOnlyButtonRadialAnimationManager.getInstance().add( button );
        }

        protected function setAccentButtonStyles( button:Button ):void {
            var skin:FadeImageSkin = new FadeImageSkin( mButtonAccentUpTexture );
            skin.setTextureForState( ButtonState.DOWN, mButtonAccentDownTexture );
            skin.setTextureForState( ButtonState.DISABLED, mButtonAccentDisabledTexture );
            skin.width = skin.height = mControlSize;
            skin.scale9Grid = BUTTON_SCALE9_GRID;
            button.defaultSkin = skin;

            setBaseButtonStyles( button );

            tintButtonIcon( button, COLOR_UI_DARK );

	        button.fontStyles = mDarkRegularTF.clone();
	        button.disabledFontStyles = mAccentRegularDisabledTF.clone();

            ButtonRadialAnimationManager.getInstance().add( button );
        }

        protected function setCallToActionPrimaryButtonStyles( button:Button ):void {
            var skin:FadeImageSkin = new FadeImageSkin( mButtonCallToActionPrimaryUpTexture );
            skin.setTextureForState( ButtonState.DOWN, mButtonCallToActionPrimaryDownTexture );
            skin.setTextureForState( ButtonState.DISABLED, mButtonCallToActionPrimaryDisabledTexture );
            skin.width = skin.height = mLargeControlSize;
            skin.scale9Grid = BUTTON_CALL_TO_ACTION_SCALE9_GRID;
            button.defaultSkin = skin;

            setBaseButtonStyles( button, 1.0 );

            setBaseCallToActionButtonStyles( button );
        }

        protected function setCallToActionAccentButtonStyles( button:Button ):void {
            var skin:FadeImageSkin = new FadeImageSkin( mButtonCallToActionAccentUpTexture );
            skin.setTextureForState( ButtonState.DOWN, mButtonCallToActionAccentDownTexture );
            skin.setTextureForState( ButtonState.DISABLED, mButtonCallToActionAccentDisabledTexture );
            skin.width = skin.height = mLargeControlSize;
            skin.scale9Grid = BUTTON_CALL_TO_ACTION_SCALE9_GRID;
            button.defaultSkin = skin;

            setBaseButtonStyles( button, 1.0 );

            setBaseCallToActionButtonStyles( button );

            tintButtonIcon( button, COLOR_UI_DARK );
        }

        protected function setBackButtonStyles( button:Button ):void {
            var skin:FadeImageSkin = new FadeImageSkin( mButtonBackUpTexture );
            skin.setTextureForState( ButtonState.DOWN, mButtonBackDownTexture );
            skin.setTextureForState( ButtonState.DISABLED, mButtonBackDisabledTexture );
            skin.width = skin.height = mControlSize;
            skin.scale9Grid = BUTTON_BACK_SCALE9_GRID;
            button.defaultSkin = skin;

            setBaseButtonStyles( button );

            /* Adjust the padding if an icon is used */
            if( button.defaultIcon ) {
                if( button.iconPosition == RelativePosition.LEFT ) {
                    button.paddingLeft = mRegularPaddingSize;
                    return;
                } else if( button.iconPosition == RelativePosition.RIGHT ) {
                    button.paddingRight = mSmallPaddingSize;
                }
            }
            /* If there is no icon, or the icon is on the right then adjust left padding */
            button.paddingLeft = mRegularPaddingSize + mSmallPaddingSize;

            BackButtonRadialAnimationManager.getInstance().add( button );
        }

        protected function setForwardButtonStyles( button:Button ):void {
            var skin:FadeImageSkin = new FadeImageSkin( mButtonForwardUpTexture );
            skin.setTextureForState( ButtonState.DOWN, mButtonForwardDownTexture );
            skin.setTextureForState( ButtonState.DISABLED, mButtonForwardDisabledTexture );
            skin.width = skin.height = mControlSize;
            skin.scale9Grid = BUTTON_FORWARD_SCALE9_GRID;
            button.defaultSkin = skin;

            setBaseButtonStyles( button );

            /* Adjust the padding if an icon is used */
            if( button.defaultIcon ) {
                if( button.iconPosition == RelativePosition.LEFT ) {
                    button.paddingLeft = mSmallPaddingSize;
                } else if( button.iconPosition == RelativePosition.RIGHT ) {
                    button.paddingRight = mRegularPaddingSize;
                    return;
                }
            }
            /* If there is no icon, or the icon is on the left then adjust right padding */
            button.paddingRight = mRegularPaddingSize + mSmallPaddingSize;

            ForwardButtonRadialAnimationManager.getInstance().add( button );
        }

        /**
         * ButtonGroup
         */

        protected function setButtonGroupStyles( group:ButtonGroup ):void {
            group.gap = mRegularPaddingSize;
        }

        /**
         * Callout
         */

        protected function setCalloutStyles( callout:Callout ):void {
            var backgroundSkin:Image = new Image( mBackgroundPopUpTexture );
            backgroundSkin.scale9Grid = BACKGROUND_POPUP_SCALE9_GRID;
            backgroundSkin.width = mRegularPaddingSize;
            backgroundSkin.height = mRegularPaddingSize;
            callout.backgroundSkin = backgroundSkin;

            var upArrowSkin:Image = new Image( mCalloutUpArrowTexture );
            callout.topArrowSkin = upArrowSkin;
            callout.topArrowGap = -5;

            var rightArrowSkin:Image = new Image( mCalloutRightArrowTexture );
            callout.rightArrowSkin = rightArrowSkin;
            callout.rightArrowGap = -7;

            var downArrowSkin:Image = new Image( mCalloutDownArrowTexture );
            callout.bottomArrowSkin = downArrowSkin;
            callout.bottomArrowGap = -8;

            var leftArrowSkin:Image = new Image( mCalloutLeftArrowTexture );
            callout.leftArrowSkin = leftArrowSkin;
            callout.leftArrowGap = -7;

            callout.padding = mRegularPaddingSize;
        }

        /**
         * Check
         */

        protected function setCheckStyles( check:Check ):void {
            var icon:FadeImageSkin = new FadeImageSkin( mCheckUpIconTexture );
            icon.selectedTexture = mCheckSelectedUpIconTexture;
            icon.setTextureForState( ButtonState.DOWN, mCheckDownIconTexture );
            icon.setTextureForState( ButtonState.DISABLED, mCheckDisabledIconTexture );
            icon.setTextureForState( ButtonState.DOWN_AND_SELECTED, mCheckSelectedDownIconTexture );
            icon.setTextureForState( ButtonState.DISABLED_AND_SELECTED, mCheckSelectedDisabledIconTexture );
            icon.fadeOutTransition = Transitions.EASE_OUT;

            check.defaultIcon = icon;

            check.gap = mExtraSmallPaddingSize;
            check.minTouchWidth = check.minTouchHeight = mControlSize;
            check.isQuickHitAreaEnabled = true;

	        check.fontStyles = mLightRegularSmallTF.clone();
	        check.disabledFontStyles = mLightRegularSmallDisabledTF.clone();

            ToggleRadialAnimationManager.getInstance().add( check );
        }

        /**
         * DateTimeSpinner
         */

        protected function setDateTimeSpinnerStyles( list:DateTimeSpinner ):void {
            list.customItemRendererStyleName = THEME_STYLE_NAME_DATE_TIME_SPINNER_LIST_ITEM_RENDERER;
        }

        protected function setDateTimeSpinnerListStyles( list:SpinnerList ):void {
            list.verticalScrollPolicy = ScrollPolicy.ON;
            list.padding = 1;
            const backgroundSkin:Image = new Image( mDateTimeSpinnerBackgroundTexture );
            backgroundSkin.scale9Grid = DATE_TIME_SPINNER_BACKGROUND_SCALE9_GRID;
            backgroundSkin.width = mControlSize;
            list.backgroundSkin = backgroundSkin;
            const overlaySkin:Image = new Image( mSpinnerListSelectionOverlayTexture );
            overlaySkin.scale9Grid = SPINNER_LIST_OVERLAY_SCALE9_GRID;
            list.selectionOverlaySkin = overlaySkin;
        }

        protected function setDateTimeSpinnerListItemRendererStyles( renderer:DefaultListItemRenderer ):void {
            setSpinnerListItemRendererStyles( renderer );

	        renderer.defaultSkin.width = mControlSize;
            renderer.paddingLeft = mSmallPaddingSize;
            renderer.paddingRight = mSmallPaddingSize;
            renderer.accessoryPosition = RelativePosition.LEFT;
            renderer.gap = renderer.minGap = renderer.accessoryGap = renderer.minAccessoryGap = mSmallPaddingSize;
        }

        /**
         * Drawers
         */

        protected function setDrawersStyles( drawers:Drawers ):void {
            var overlaySkin:Image = new Image( mBackgroundDrawersTexture );
            overlaySkin.scale9Grid = BACKGROUND_SCALE9_GRID;
            drawers.overlaySkin = overlaySkin;
        }

        /**
         * Grouped list
         */

        protected function setGroupedListStyles( list:GroupedList ):void {
            setScrollerStyles( list );
            const backgroundSkin:Image = new Image( mBackgroundPlainTexture );
            backgroundSkin.scale9Grid = BACKGROUND_SCALE9_GRID;
            list.backgroundSkin = backgroundSkin;
            list.customLastItemRendererStyleName = THEME_STYLE_NAME_GROUPED_LIST_LAST_ITEM_RENDERER;
        }

        protected function setGroupedListHeaderRendererStyles( renderer:DefaultGroupedListHeaderOrFooterRenderer ):void {
            const backgroundSkin:Image = new Image( mGroupedListHeaderTexture );
            backgroundSkin.scale9Grid = LIST_ITEM_SCALE9_GRID;
            renderer.backgroundSkin = backgroundSkin;

            renderer.horizontalAlign = RelativePosition.LEFT;
            renderer.padding = mSmallPaddingSize;

            renderer.contentLoaderFactory = imageLoaderFactory;

	        renderer.fontStyles = mAccentBoldTF.clone();
	        renderer.disabledFontStyles = mLightRegularDisabledTF.clone();
        }

        protected function setGroupedListFooterRendererStyles( renderer:DefaultGroupedListHeaderOrFooterRenderer ):void {
            const backgroundSkin:Image = new Image( mGroupedListHeaderTexture );
            backgroundSkin.scale9Grid = LIST_ITEM_SCALE9_GRID;
            renderer.backgroundSkin = backgroundSkin;

            renderer.horizontalAlign = RelativePosition.LEFT;
            renderer.padding = mSmallPaddingSize;
            renderer.customContentLabelStyleName = THEME_STYLE_NAME_GROUPED_LIST_FOOTER_CONTENT_LABEL;

            renderer.contentLoaderFactory = imageLoaderFactory;

	        renderer.fontStyles = mLightBoldTF.clone();
	        renderer.disabledFontStyles = mLightBoldTF.clone();
        }

        /**
         * Header
         */

        protected function setHeaderStyles( header:Header ):void {
            setHeaderWithoutBackgroundStyles( header, false );

            var backgroundSkin:Image = new Image( mHeaderBackgroundTexture );
            backgroundSkin.scale9Grid = BACKGROUND_SCALE9_GRID;
            backgroundSkin.width = mControlSize;
            backgroundSkin.height = mHeaderSize;
            header.backgroundSkin = backgroundSkin;
            header.paddingLeft = header.paddingRight = mSmallPaddingSize;
        }

        protected function setHeaderWithShadowStyles( header:Header ):void {
            setHeaderWithoutBackgroundStyles( header, false );

            var backgroundSkin:Image = new Image( mHeaderShadowBackgroundTexture );
            backgroundSkin.width = mControlSize;
            backgroundSkin.height = mHeaderShadowSize;
            backgroundSkin.scale9Grid = HEADER_SHADOW_SCALE9_GRID;
            header.maxHeight = mHeaderShadowSize;
            header.paddingTop = -8.5;
            header.paddingLeft = header.paddingRight = 0;
            header.backgroundSkin = backgroundSkin;
        }

        protected function setHeaderWithoutBackgroundStyles( header:Header, addInvisibleSkin:Boolean = true ):void {
            if( addInvisibleSkin ) {
                var invisibleSkin:Quad = new Quad( mHeaderSize, mHeaderSize );
                invisibleSkin.alpha = 0;
                header.backgroundSkin = invisibleSkin;
            }
            header.gap = mRegularPaddingSize;
            header.paddingLeft = header.paddingRight = mRegularPaddingSize;
            header.titleGap = mRegularPaddingSize;
            header.maxHeight = mHeaderSize;
            header.titleAlign = HorizontalAlign.CENTER;
	        header.fontStyles = mLightBoldLargeTF.clone();
        }

        /**
         * Label
         */

        protected function setLabelStyles( label:Label ):void {
            label.fontStyles = mLightRegularTF.clone();
            label.disabledFontStyles = mLightRegularDisabledTF.clone();
        }

        protected function setHeadingLabelStyles( label:Label ):void {
            label.fontStyles = mLightBoldLargeTF.clone();
            label.disabledFontStyles = mLightBoldLargeDisabledTF.clone();
        }

        protected function setDetailLabelStyles( label:Label ):void {
            label.fontStyles = mLightRegularSmallTF.clone();
            label.disabledFontStyles = mLightRegularSmallDisabledTF.clone();
        }

        /**
         * LayoutGroup
         */

        protected function setLayoutGroupToolbarStyles( group:LayoutGroup ):void {
            var backgroundSkin:Image = new Image( mBackgroundToolbarTexture );
            backgroundSkin.scale9Grid = BACKGROUND_SCALE9_GRID;
            backgroundSkin.width = 48;
            backgroundSkin.height = 48;
            group.backgroundSkin = backgroundSkin;
        }

        /**
         * List
         */

        protected function setListStyles( list:List ):void {
            setScrollerStyles( list );
            const backgroundSkin:Image = new Image( mBackgroundPlainTexture );
            backgroundSkin.scale9Grid = BACKGROUND_SCALE9_GRID;
            list.backgroundSkin = backgroundSkin;
        }

        protected function setItemRendererStyles( renderer:BaseDefaultItemRenderer ):void {
            const skin:FadeImageSkin = new FadeImageSkin( mListItemRendererUpTexture );
            skin.setTextureForState( ButtonState.DOWN, mListItemRendererDownTexture );
            skin.selectedTexture = mListItemRendererSelectedTexture;
            skin.width = skin.height = mLargeControlSize;
            skin.scale9Grid = LIST_ITEM_SCALE9_GRID;
            renderer.defaultSkin = skin;

            renderer.horizontalAlign = RelativePosition.LEFT;
            renderer.paddingLeft = renderer.paddingRight = mSmallPaddingSize;
            renderer.gap = mRegularPaddingSize;
            renderer.minGap = mRegularPaddingSize;
            renderer.iconPosition = RelativePosition.LEFT;
            renderer.accessoryGap = Number.POSITIVE_INFINITY;
            renderer.minAccessoryGap = mRegularPaddingSize;
            renderer.accessoryPosition = RelativePosition.RIGHT;

            renderer.accessoryLoaderFactory = imageLoaderFactory;
            renderer.iconLoaderFactory = imageLoaderFactory;

            renderer.fontStyles = mLightRegularTF.clone();
            renderer.disabledFontStyles = mLightRegularDisabledTF.clone();
            renderer.accessoryLabelFontStyles = mLightRegularTF.clone();
            renderer.iconLabelFontStyles = mLightRegularTF.clone();

            /* Add animation manager only if the list for this item is selectable */
            var isSelectable:Boolean = true;
            if( renderer.parent is GroupedListDataViewPort ) {
                isSelectable = GroupedListDataViewPort( renderer.parent ).isSelectable;
            } else if( renderer.parent is ListDataViewPort ) {
                isSelectable = ListDataViewPort( renderer.parent ).isSelectable;
            }
            if( isSelectable ) {
                ListItemRadialAnimationManager.getInstance().add( renderer );
            }
        }

        /**
         * Numeric stepper
         */

        protected function setNumericStepperStyles( stepper:NumericStepper ):void {
            stepper.buttonLayoutMode = StepperButtonLayoutMode.SPLIT_HORIZONTAL;
            stepper.incrementButtonLabel = "+";
            stepper.decrementButtonLabel = "-";
        }

        protected function setNumericStepperTextInputStyles( input:TextInput ):void {
            const backgroundSkin:Image = new Image( mTextInputUpTexture );
            backgroundSkin.scale9Grid = INPUT_SCALE9_GRID;
            backgroundSkin.width = backgroundSkin.height = mControlSize;
            input.backgroundSkin = backgroundSkin;

            input.isEditable = false;
            input.isSelectable = false;
            input.textEditorFactory = stepperTextEditorFactory;

            // Align to the center
            var format:TextFormat = new TextFormat();
            format.copyFrom( mLightRegularTF );
            format.horizontalAlign = Align.CENTER;
            input.fontStyles = format;
            format = new TextFormat();
            format.copyFrom( mLightRegularDisabledTF );
            format.horizontalAlign = Align.CENTER;
            input.disabledFontStyles = format;
        }

        protected function setNumericStepperButtonStyles( button:Button ):void {
            setAccentQuietButtonStyles( button );

            button.paddingLeft = button.paddingRight = mSmallPaddingSize;
            button.keepDownStateOnRollOut = true;

            button.fontStyles = mAccentBoldExtraLargeTF.clone();
            button.disabledFontStyles = mAccentBoldExtraLargeDisabledTF.clone();
        }

        /**
         * Panel
         */

        protected function setBasePanelStyles( panel:Panel ):void {
            setScrollerStyles( panel );

            panel.paddingLeft = panel.paddingRight = panel.paddingBottom = 0;
            const backgroundSkin:Image = new Image( mBackgroundPlainTexture );
            backgroundSkin.scale9Grid = BACKGROUND_SCALE9_GRID;
            panel.backgroundSkin = backgroundSkin;
        }

        protected function setPanelWithPaddingStyles( panel:Panel ):void {
            setBasePanelStyles( panel );

            panel.paddingTop = panel.paddingBottom = 0;
            panel.paddingRight = mSmallPaddingSize;
            panel.paddingLeft = mSmallPaddingSize;
        }

        protected function setPanelWithShadowStyles( panel:Panel ):void {
            setPanelWithPaddingStyles( panel );

            panel.customHeaderStyleName = THEME_STYLE_NAME_HEADER_WITH_SHADOW;
            panel.paddingTop = -8.5;
        }

        /**
         * Panel Screen
         */

        protected function setBasePanelScreenHeaderStyles( header:Header ):void {
            header.useExtraPaddingForOSStatusBar = true;
        }

        protected function setPanelScreenHeaderStyles( header:Header ):void {
            setHeaderStyles( header );
            setBasePanelScreenHeaderStyles( header );
            header.paddingLeft = header.paddingRight = 0;
        }

        protected function setPanelScreenHeaderWithShadowStyles( header:Header ):void {
            setHeaderWithShadowStyles( header );
            setBasePanelScreenHeaderStyles( header );
        }

        /**
         * Page indicator
         */

        protected function setPageIndicatorStyles( pageIndicator:PageIndicator ):void {
            pageIndicator.normalSymbolFactory = pageIndicatorNormalSymbolFactory;
            pageIndicator.selectedSymbolFactory = pageIndicatorSelectedSymbolFactory;
            pageIndicator.gap = mSmallPaddingSize;
            pageIndicator.padding = mRegularPaddingSize;
            pageIndicator.minTouchWidth = mControlSize;
            pageIndicator.minTouchHeight = mControlSize;

            PageIndicatorRadialAnimationManager.add( pageIndicator );
        }

        /**
         * Picker list
         */

        protected function setPickerListStyles( list:PickerList ):void {
            if( DeviceCapabilities.isTablet( Starling.current.nativeStage ) ) {
                list.popUpContentManager = new DropDownPopUpContentManager();
            } else {
                const manager:VerticalCenteredPopUpContentManager = new VerticalCenteredPopUpContentManager();
                manager.marginLeft = manager.marginRight = manager.marginBottom = manager.marginTop = mRegularPaddingSize;
                list.popUpContentManager = manager;
            }
        }

        protected function setPickerListButtonStyles( button:Button ):void {
            var skin:FadeImageSkin = new FadeImageSkin( mButtonPrimaryUpTexture );
            skin.setTextureForState( ButtonState.DOWN, mButtonPrimaryDownTexture );
            skin.setTextureForState( ButtonState.DISABLED, mButtonPrimaryDisabledTexture );
            skin.width = skin.height = mControlSize;
            skin.scale9Grid = BUTTON_SCALE9_GRID;
            button.defaultSkin = skin;
            setBaseButtonStyles( button );

            var icon:ImageSkin = new ImageSkin( mPickerListButtonIcon );
            icon.setTextureForState( ButtonState.DISABLED, mPickerListButtonDisabledIcon );
            button.defaultIcon = icon;

            button.gap = Number.POSITIVE_INFINITY;
            button.minGap = mSmallPaddingSize;
            button.paddingLeft = mRegularPaddingSize;
            button.iconOffsetY = 0;
            button.iconPosition = RelativePosition.RIGHT;

            ButtonRadialAnimationManager.getInstance().add( button );
        }

        protected function setPickerListListStyles( list:List ):void {
            setScrollerStyles( list );
            if( DeviceCapabilities.isTablet( Starling.current.nativeStage ) ) {
                list.maxHeight = 250;
            }
            list.verticalScrollPolicy = ScrollPolicy.ON;
            const backgroundSkin:Image = new Image( mDropDownListBackgroundTexture );
            backgroundSkin.scale9Grid = DROP_DOWN_LIST_BACKGROUND_SCALE9_GRID;
            list.backgroundSkin = backgroundSkin;
            list.paddingLeft = 4.5;
            list.paddingRight = 4;
            list.paddingBottom = 5;
            list.paddingTop = 3.5;
            list.customItemRendererStyleName = THEME_STYLE_NAME_DROP_DOWN_LIST_ITEM_RENDERER;
        }

        protected function setPickerListItemRendererStyles( renderer:BaseDefaultItemRenderer ):void {
            setBaseDropDownListItemRendererStyles( renderer );

            ListItemRadialAnimationManager.getInstance().add( renderer );
        }

        /**
         * Progress bar
         */

        protected function setProgressBarStyles( progress:ProgressBar ):void {
            var fillSkin:ImageSkin;
            var fillDisabledSkin:ImageSkin;
            var backgroundSkin:ImageSkin;
            var backgroundDisabledSkin:ImageSkin;

            backgroundSkin = getProgressBarSkin( mProgressBarBackgroundTexture );
            backgroundDisabledSkin = getProgressBarSkin( mProgressBarBackgroundDisabledTexture );
            fillSkin = getProgressBarSkin( mProgressBarFillTexture );
            fillDisabledSkin = getProgressBarSkin( mProgressBarBackgroundTexture );

            progress.backgroundSkin = backgroundSkin;
            progress.backgroundDisabledSkin = backgroundDisabledSkin;

            progress.fillSkin = fillSkin;
            progress.fillDisabledSkin = fillDisabledSkin;

            if( progress.direction == Direction.HORIZONTAL ) {
                backgroundSkin.minWidth = backgroundDisabledSkin.minWidth = fillSkin.minWidth = fillDisabledSkin.minWidth = mControlSize << 1;
            } else {
                backgroundSkin.minHeight = backgroundDisabledSkin.minHeight = fillSkin.minHeight = fillDisabledSkin.minHeight = mControlSize << 1;
            }

            /* Helper */
            function getProgressBarSkin( texture:Texture ):ImageSkin {
                var skin:ImageSkin = new ImageSkin( texture );
                skin.width = mTrackSize;
                skin.height = mTrackSize;
                skin.scale9Grid = PROGRESS_BAR_SCALE9_GRID;
                return skin;
            }
        }

        /**
         * Radio
         */

        protected function setRadioStyles( radio:Radio ):void {
            var icon:FadeImageSkin = new FadeImageSkin( mRadioUpIconTexture );
            icon.selectedTexture = mRadioSelectedUpIconTexture;
            icon.setTextureForState( ButtonState.DOWN, mRadioDownIconTexture );
            icon.setTextureForState( ButtonState.DISABLED, mRadioDisabledIconTexture );
            icon.setTextureForState( ButtonState.DOWN_AND_SELECTED, mRadioSelectedDownIconTexture );
            icon.setTextureForState( ButtonState.DISABLED_AND_SELECTED, mRadioSelectedDisabledIconTexture );
            icon.fadeOutTransition = Transitions.EASE_OUT;

            radio.gap = mExtraSmallPaddingSize;
            radio.defaultIcon = icon;

            radio.fontStyles = mLightRegularSmallTF.clone();
            radio.disabledFontStyles = mLightRegularSmallDisabledTF.clone();

            ToggleRadialAnimationManager.getInstance().add( radio );
        }

        /**
         * Scroll bar
         */

        protected function setSimpleScrollBarStyles( scrollBar:SimpleScrollBar ):void {
            if( scrollBar.direction == Direction.HORIZONTAL ) {
                scrollBar.customThumbStyleName = THEME_STYLE_NAME_HORIZONTAL_SIMPLE_SCROLL_BAR_THUMB;
            } else {
                scrollBar.customThumbStyleName = THEME_STYLE_NAME_VERTICAL_SIMPLE_SCROLL_BAR_THUMB;
            }
            const padding:int = mSmallPaddingSize >> 2;
            scrollBar.paddingRight = scrollBar.paddingTop = scrollBar.paddingBottom = padding;
        }

        protected function setHorizontalSimpleScrollBarThumbStyles( thumb:Button ):void {
            var skin:Image = new Image( mHorizontalScrollBarTexture );
            skin.height = 26;
            skin.scale9Grid = HORIZONTAL_SCROLL_BAR_SCALE9_GRID;
            thumb.defaultSkin = skin;
            thumb.hasLabelTextRenderer = false;
        }

        protected function setVerticalSimpleScrollBarThumbStyles( thumb:Button ):void {
            var skin:Image = new Image( mVerticalScrollBarTexture );
            skin.height = 26;
            skin.scale9Grid = VERTICAL_SCROLL_BAR_SCALE9_GRID;
            thumb.defaultSkin = skin;
            thumb.hasLabelTextRenderer = false;
        }

        /**
         * Scroll container
         */

        protected function setScrollContainerStyles( container:ScrollContainer ):void {
            setScrollerStyles( container );
        }

        protected function setToolbarScrollContainerStyles( container:ScrollContainer ):void {
            setScrollerStyles( container );
            if( !container.layout ) {
                var layout:HorizontalLayout = new HorizontalLayout();
                layout.padding = mRegularPaddingSize;
                layout.gap = mRegularPaddingSize;
                container.layout = layout;
            }

            const backgroundSkin:Image = new Image( mBackgroundPlainTexture );
            backgroundSkin.scale9Grid = BACKGROUND_SCALE9_GRID;
            backgroundSkin.width = backgroundSkin.height = mControlSize;
            container.backgroundSkin = backgroundSkin;
        }

        /**
         * Scroll text
         */

        protected function setScrollTextStyles( text:ScrollText ):void {
            setScrollerStyles( text );

            text.fontStyles = mLightRegularTF.clone();
            text.disabledFontStyles = mLightRegularDisabledTF.clone();
            text.padding = mRegularPaddingSize;
            text.paddingRight = mRegularPaddingSize + mSmallPaddingSize;
        }

        /**
         * Slider
         */

        protected function setSliderStyles( slider:Slider ):void {
            slider.trackLayoutMode = TrackLayoutMode.SPLIT;
            slider.minimumPadding = slider.maximumPadding = -mSmallPaddingSize;

            if( slider.direction == Direction.VERTICAL ) {
                slider.customMinimumTrackStyleName = THEME_STYLE_NAME_VERTICAL_SLIDER_MINIMUM_TRACK;
                slider.customMaximumTrackStyleName = THEME_STYLE_NAME_VERTICAL_SLIDER_MAXIMUM_TRACK;
            } else {
                slider.customMinimumTrackStyleName = THEME_STYLE_NAME_HORIZONTAL_SLIDER_MINIMUM_TRACK;
                slider.customMaximumTrackStyleName = THEME_STYLE_NAME_HORIZONTAL_SLIDER_MAXIMUM_TRACK;
            }

            slider.thumbFactory = function ():Button {
                return new AnimatedSliderThumb();
            };
        }

        protected function setSliderThumbStyles( thumb:Button ):void {
            thumb.hasLabelTextRenderer = false;
            thumb.isQuickHitAreaEnabled = true;
            thumb.minTouchWidth = thumb.minTouchHeight = mControlSize;
        }

        protected function setHorizontalSliderMinimumTrackStyles( track:Button ):void {
            var skin:ImageSkin = new ImageSkin( mSliderHorizontalFillTexture );
            skin.disabledTexture = mSliderHorizontalBackgroundDisabledTexture;
            skin.width = mWideControlSize * 2;
            skin.height = mTrackSize * 0.5;
            skin.scale9Grid = SLIDER_HORIZONTAL_SCALE9_GRID;

            track.defaultSkin = skin;
            track.hasLabelTextRenderer = false;
            track.isQuickHitAreaEnabled = true;
            track.minTouchHeight = mRegularPaddingSize;
        }

        protected function setHorizontalSliderMaximumTrackStyles( track:Button ):void {
            var skin:ImageSkin = new ImageSkin( mSliderHorizontalBackgroundTexture );
            skin.disabledTexture = mSliderHorizontalBackgroundDisabledTexture;
            skin.width = mWideControlSize * 2;
            skin.height = mTrackSize * 0.5;
            skin.scale9Grid = SLIDER_HORIZONTAL_SCALE9_GRID;

            track.defaultSkin = skin;
            track.hasLabelTextRenderer = false;
            track.isQuickHitAreaEnabled = true;
            track.minTouchHeight = mRegularPaddingSize;
        }

        protected function setVerticalSliderMinimumTrackStyles( track:Button ):void {
            var skin:ImageSkin = new ImageSkin( mSliderVerticalFillTexture );
            skin.disabledTexture = mSliderVerticalBackgroundDisabledTexture;
            skin.width = mTrackSize * 0.5;
            skin.height = mWideControlSize * 2;
            skin.scale9Grid = SLIDER_VERTICAL_SCALE9_GRID;

            track.defaultSkin = skin;
            track.hasLabelTextRenderer = false;
            track.isQuickHitAreaEnabled = true;
            track.minTouchWidth = mRegularPaddingSize;
        }

        protected function setVerticalSliderMaximumTrackStyles( track:Button ):void {
            var skin:ImageSkin = new ImageSkin( mSliderVerticalBackgroundTexture );
            skin.disabledTexture = mSliderVerticalBackgroundDisabledTexture;
            skin.width = mTrackSize * 0.5;
            skin.height = mWideControlSize * 2;
            skin.scale9Grid = SLIDER_VERTICAL_SCALE9_GRID;

            track.defaultSkin = skin;
            track.hasLabelTextRenderer = false;
            track.isQuickHitAreaEnabled = true;
            track.minTouchWidth = mRegularPaddingSize;
        }

        /**
         * Spinner list
         */

        protected function setSpinnerListStyles( list:SpinnerList ):void {
            list.verticalScrollPolicy = ScrollPolicy.ON;
            list.paddingTop = 4;
            list.paddingLeft = 4.5;
            list.paddingRight = 4;
            list.paddingBottom = 5;
            const backgroundSkin:Image = new Image( mDropDownListBackgroundTexture );
            backgroundSkin.scale9Grid = DROP_DOWN_LIST_BACKGROUND_SCALE9_GRID;
            backgroundSkin.width = mWideControlSize * 2;
            list.backgroundSkin = backgroundSkin;
            const overlaySkin:Image = new Image( mSpinnerListSelectionOverlayTexture );
            overlaySkin.scale9Grid = SPINNER_LIST_OVERLAY_SCALE9_GRID;
            list.selectionOverlaySkin = overlaySkin;
            list.customItemRendererStyleName = THEME_STYLE_NAME_SPINNER_LIST_ITEM_RENDERER;
        }

        protected function setSpinnerListItemRendererStyles( renderer:DefaultListItemRenderer ):void {
            /* Style is the same as for the PickerList items, except that the
             * SpinnerList's item does not have a skin for the selected and down state */
            var skin:FadeImageSkin = setBaseDropDownListItemRendererStyles( renderer );
            skin.selectedTexture = null;
            skin.setTextureForState( ButtonState.DOWN, null );
        }

        /**
         * Tab Bar
         */

        protected function setBaseTabStyles( tab:ToggleButton ):void {
            tab.paddingTop = mSmallPaddingSize;
            tab.paddingLeft = tab.paddingRight = mRegularPaddingSize;

            tab.iconPosition = RelativePosition.TOP;
            tab.gap = 7;

            tab.fontStyles = mTabUpTF.clone();
            tab.selectedFontStyles = mLightRegularTF.clone();
            tab.disabledFontStyles = mLightRegularDisabledTF.clone();

            TabButtonRadialAnimationManager.getInstance().add( tab );
        }

        protected function setTabBarStyles( tabBar:TabBar ):void {
            tabBar.distributeTabSizes = true;
            tabBar.gap = -0.5;    // Avoids occasional white space in between tabs

            /* Custom Tab that adjusts icon's alpha depending on the selected state */
            tabBar.tabFactory = function ():ToggleButton {
                return new CustomTab();
            };

            tabBar.paddingTop = -2;

            var image:Image = new Image( mAtlas.getTexture( "tab-border" ) );
            image.scale9Grid = TAB_SELECTION_SKIN_SCALE9_GRID;
            image.height = 3;
            image.alpha = 0;
            tabBar.selectionSkin = image;

            TabBarSelectionAnimationManager.add( tabBar );
        }

        protected function setInvertedTabBarStyles( tabBar:TabBar ):void {
            /* If 'tab with icon' style was added then combine styles for inverted and 'with icon' tab */
            tabBar.customTabStyleName = (tabBar.customTabStyleName == THEME_STYLE_NAME_TAB_WITH_ICON) ? THEME_STYLE_NAME_TAB_SHADOW_BOTTOM_WITH_ICON : THEME_STYLE_NAME_TAB_SHADOW_BOTTOM;

            setTabBarStyles( tabBar );

            tabBar.paddingTop = 0;
            tabBar.paddingBottom = -2;
        }

        protected function setTabBarWithIconsStyles( tabBar:TabBar ):void {
            tabBar.customTabStyleName = THEME_STYLE_NAME_TAB_WITH_ICON;

            setTabBarStyles( tabBar );
        }

        protected function setTabStyles( tab:ToggleButton ):void {
            const skin:FadeImageSkin = new FadeImageSkin( mTabUpTexture );
            skin.setTextureForState( ButtonState.DOWN, mTabDownTexture );
            skin.setTextureForState( ButtonState.DOWN_AND_SELECTED, mTabDownTexture );
            skin.scale9Grid = TAB_SCALE9_GRID;
            skin.height = mWideControlSize;
            tab.defaultSkin = skin;

            setBaseTabStyles( tab );
        }

        protected function setTabWithIconStyles( tab:ToggleButton ):void {
            setTabStyles( tab );
            /* Adjust height */
            tab.defaultSkin.height = mWideControlSize * 1.25;
        }

        protected function setInvertedTabStyles( tab:ToggleButton ):void {
            const skin:FadeImageSkin = new FadeImageSkin( mTabInvertedUpTexture );
            skin.setTextureForState( ButtonState.DOWN, mTabInvertedDownTexture );
            skin.setTextureForState( ButtonState.DOWN_AND_SELECTED, mTabInvertedDownTexture );
            skin.scale9Grid = TAB_SCALE9_GRID;
            skin.height = mWideControlSize;
            tab.defaultSkin = skin;

            setBaseTabStyles( tab );

            tab.paddingTop = -mSmallPaddingSize >> 1;
        }

        protected function setInvertedTabWithIconStyles( tab:ToggleButton ):void {
            setInvertedTabStyles( tab );

            /* Adjust height */
            tab.defaultSkin.height = mWideControlSize * 1.25;
        }

	    /**
	     * Tab navigator
	     */

	    protected function setTabNavigatorWithIconsStyles( navigator:TabNavigator ):void {
		    /* If tab bar is already styled to use 'shadow-bottom' then we need to combined these two styles */
		    if( navigator.customTabBarStyleName == THEME_STYLE_NAME_TAB_BAR_SHADOW_BOTTOM ) {
			    navigator.customTabBarStyleName = THEME_STYLE_NAME_TAB_NAVIGATOR_TAB_BAR_WITH_ICONS_SHADOW_BOTTOM;
		    } else {
			    navigator.customTabBarStyleName = THEME_STYLE_NAME_TAB_BAR_WITH_ICONS;
		    }
	    }

	    protected function setInvertedTabNavigatorStyles( navigator:TabNavigator ):void {
		    /* If tab bar is already styled to use 'with-icons' then we need to combined these two styles */
		    if( navigator.customTabBarStyleName == THEME_STYLE_NAME_TAB_BAR_WITH_ICONS ) {
			    navigator.customTabBarStyleName = THEME_STYLE_NAME_TAB_NAVIGATOR_TAB_BAR_WITH_ICONS_SHADOW_BOTTOM;
		    } else {
			    navigator.customTabBarStyleName = THEME_STYLE_NAME_TAB_BAR_SHADOW_BOTTOM;
		    }
	    }

	    protected function setCombinedNavigatorTabBarStyles( tabBar:TabBar ):void {
		    /* Apply 'with-icons' and 'shadow-bottom' styles */
		    tabBar.styleNameList.add( THEME_STYLE_NAME_TAB_BAR_WITH_ICONS );
		    tabBar.styleNameList.add( THEME_STYLE_NAME_TAB_BAR_SHADOW_BOTTOM );
		    setTabBarWithIconsStyles( tabBar );
		    setInvertedTabBarStyles( tabBar );
	    }

        /**
         * Text area
         */

        protected function setTextAreaStyles( textArea:TextArea ):void {
            setScrollerStyles( textArea );

            var skin:FadeImageSkin = new FadeImageSkin( mTextInputUpTexture );
            skin.setTextureForState( TextInputState.FOCUSED, mTextInputFocusedTexture );
            skin.scale9Grid = INPUT_SCALE9_GRID;
            skin.width = mLargeControlSize * 2;
            skin.height = mLargeControlSize * 2;

            textArea.padding = 0;
            textArea.paddingLeft = textArea.paddingRight = mSmallPaddingSize >> 2;
            textArea.focusPaddingLeft = textArea.focusPaddingRight = mSmallPaddingSize >> 2;
            textArea.backgroundSkin = skin;
            textArea.textEditorFactory = textAreaTextEditorFactory;

            textArea.fontStyles = mLightRegularTF.clone();
            textArea.disabledFontStyles = mLightRegularDisabledTF.clone();
        }

        /**
         * Text input
         */

        protected function setTextCalloutStyles( callout:TextCallout ):void {
            setCalloutStyles( callout );

            callout.fontStyles = mLightRegularTF.clone();
        }

        /**
         * Text input
         */

        protected function setTextInputStyles( input:TextInput ):void {
            var skin:FadeImageSkin = new FadeImageSkin( mTextInputUpTexture );
            skin.setTextureForState( TextInputState.FOCUSED, mTextInputFocusedTexture );
            skin.scale9Grid = INPUT_SCALE9_GRID;
            skin.width = 15;
            skin.height = mControlSize;

            input.backgroundSkin = skin;

            setBaseTextInputStyles( input );
        }

        protected function setSearchTextInputStyles( input:TextInput ):void {
            var skin:FadeImageSkin = new FadeImageSkin( mTextInputUpTexture );
            skin.setTextureForState( TextInputState.FOCUSED, mTextInputFocusedTexture );
            skin.scale9Grid = INPUT_SCALE9_GRID;
            skin.width = mControlSize * 2;
            skin.height = mControlSize;

            input.gap = mSmallPaddingSize;
            input.backgroundSkin = skin;

            var icon:FadeImageSkin = new FadeImageSkin( mSearchIconUpTexture );
            icon.setTextureForState( TextInputState.FOCUSED, mSearchIconFocusedTexture );
            input.defaultIcon = icon;

            setBaseTextInputStyles( input );
            input.paddingLeft = mSmallPaddingSize;
        }

        /**
         * ToggleSwitch
         */

        protected function setToggleSwitchStyles( toggle:ToggleSwitch ):void {
            toggle.paddingLeft = toggle.paddingRight = -3;
            toggle.showLabels = false;
            toggle.trackLayoutMode = TrackLayoutMode.SPLIT;
            toggle.toggleThumbSelection = true;
            toggle.minTouchWidth = toggle.minTouchHeight = mControlSize;
            toggle.isQuickHitAreaEnabled = true;
            toggle.toggleDuration = 0.3;
            /* Use ToggleButton so that the thumb can have different skin for on and off states */
            toggle.thumbFactory = function ():Button {
                return new ToggleButton();
            };

            ToggleRadialAnimationManager.getInstance().add( toggle );
        }

        protected function setToggleSwitchOnTrackStyles( track:Button ):void {
            var skin:ImageSkin = new ImageSkin( mToggleSwitchTrackOnTexture );
            skin.disabledTexture = mToggleSwitchTrackDisabledTexture;
            skin.width = 25;
            skin.height = 14;
            skin.scale9Grid = TOGGLE_SWITCH_TRACK_SCALE9_GRID;

            track.defaultSkin = skin;
            track.maxWidth = 25;
            track.hasLabelTextRenderer = false;
        }

        protected function setToggleSwitchOffTrackStyles( track:Button ):void {
            var skin:ImageSkin = new ImageSkin( mToggleSwitchTrackOffTexture );
            skin.disabledTexture = mToggleSwitchTrackDisabledTexture;
            skin.width = 25;
            skin.height = 14;
            skin.scale9Grid = TOGGLE_SWITCH_TRACK_SCALE9_GRID;

            track.defaultSkin = skin;
            track.maxWidth = 25;
            track.hasLabelTextRenderer = false;
        }

        protected function setToggleSwitchThumbStyles( thumb:Button ):void {
            var skin:ImageSkin = new ImageSkin( mToggleSwitchThumbOffTexture );
            skin.defaultTexture = mToggleSwitchThumbOffTexture;
            skin.selectedTexture = mToggleSwitchThumbOnTexture;
            skin.disabledTexture = mToggleSwitchThumbDisabledTexture;
            skin.width = 24;
            skin.height = 25;
            skin.scale9Grid = TOGGLE_SWITCH_THUMB_SCALE9_GRID;

            thumb.defaultSkin = skin;
            thumb.hasLabelTextRenderer = false;
            thumb.isQuickHitAreaEnabled = true;
            thumb.minTouchWidth = thumb.minTouchHeight = mControlSize;
        }

        /**
         * Tree
         */

        protected function setTreeStyles( tree:Tree ):void {
            this.setScrollerStyles( tree );
            const backgroundSkin:Image = new Image( mBackgroundPlainTexture );
            backgroundSkin.scale9Grid = BACKGROUND_SCALE9_GRID;
            tree.backgroundSkin = backgroundSkin;
        }

        protected function setTreeItemRendererStyles( renderer:DefaultTreeItemRenderer ):void {
            this.setItemRendererStyles( renderer );

            renderer.gap = mSmallPaddingSize;
            renderer.minGap = mSmallPaddingSize;
            renderer.indentation = mTreeDisclosureOpenIconTexture.width;

            var disclosureOpenIcon:ImageSkin = new ImageSkin( mTreeDisclosureOpenIconTexture );
            disclosureOpenIcon.scale = 0.75;
            disclosureOpenIcon.defaultColor = COLOR_UI_LIGHT;
            disclosureOpenIcon.minTouchWidth = mSmallerControlSize;
            disclosureOpenIcon.minTouchHeight = mSmallerControlSize;
            renderer.disclosureOpenIcon = disclosureOpenIcon;

            var disclosureClosedIcon:ImageSkin = new ImageSkin( mTreeDisclosureClosedIconTexture );
            disclosureClosedIcon.scale = 0.75;
            disclosureClosedIcon.defaultColor = COLOR_UI_LIGHT;
            disclosureClosedIcon.minTouchWidth = mSmallerControlSize;
            disclosureClosedIcon.minTouchHeight = mSmallerControlSize;
            renderer.disclosureClosedIcon = disclosureClosedIcon;
        }

        /**
         *
         *
         * Media controls
         *
         *
         */

        protected function setSeekSliderStyles( slider:SeekSlider ):void {
            slider.minimumPadding = slider.maximumPadding = -mSmallPaddingSize;
            slider.trackLayoutMode = TrackLayoutMode.SPLIT;
            slider.thumbFactory = function ():Button {
                return new AnimatedSeekSliderThumb();
            };
        }

        protected function setSeekSliderThumbStyles( thumb:Button ):void {
            thumb.hasLabelTextRenderer = false;
            thumb.isQuickHitAreaEnabled = true;
            thumb.minTouchWidth = thumb.minTouchHeight = mControlSize;
        }

        protected function setSeekSliderMinimumTrackStyles( track:Button ):void {
            var defaultSkin:Image = new Image( mSeekSliderFillTexture );
            defaultSkin.scale9Grid = SEEK_SLIDER_SCALE9_GRID;
            defaultSkin.width = defaultSkin.height = 2;

            track.defaultSkin = defaultSkin;
            track.hasLabelTextRenderer = false;
        }

        protected function setSeekSliderMaximumTrackStyles( track:Button ):void {
            var defaultSkin:Image = new Image( mSeekSliderBackgroundTexture );
            defaultSkin.scale9Grid = SEEK_SLIDER_SCALE9_GRID;
            defaultSkin.width = defaultSkin.height = 2;

            track.defaultSkin = defaultSkin;
            track.hasLabelTextRenderer = false;
        }

        /**
         * Play/pause button
         */

        protected function setPlayPauseToggleButtonStyles( button:PlayPauseToggleButton ):void {
            setHeaderQuietButtonIconOnlyStyles( button );

            var icon:ImageSkin = new ImageSkin( mPlayIconTexture );
            icon.selectedTexture = mPauseIconTexture;
            icon.setTextureForState( ButtonState.DOWN, mPlayIconTexture );
            icon.setTextureForState( ButtonState.DOWN_AND_SELECTED, mPauseIconTexture );

            button.defaultIcon = icon;
            button.hasLabelTextRenderer = false;
        }

        /**
         * Mute button
         */

        protected function setMuteToggleButtonStyles( button:MuteToggleButton ):void {
            setHeaderQuietButtonIconOnlyStyles( button );

            var icon:ImageSkin = new ImageSkin( mVolumeUpIconTexture );
            icon.selectedTexture = mVolumeDownIconTexture;
            icon.setTextureForState( ButtonState.DOWN, mVolumeUpIconTexture );
            icon.setTextureForState( ButtonState.DOWN_AND_SELECTED, mVolumeDownIconTexture );

            button.defaultIcon = icon;
            button.hasLabelTextRenderer = false;
            button.showVolumeSliderOnHover = false;
        }

        /**
         * Full screen button
         */

        protected function setFullScreenToggleButtonStyles( button:FullScreenToggleButton ):void {
            setHeaderQuietButtonIconOnlyStyles( button );

            var icon:ImageSkin = new ImageSkin( mFullScreenEnterIconTexture );
            icon.selectedTexture = mFullScreenExitIconTexture;
            icon.setTextureForState( ButtonState.DOWN, mFullScreenEnterIconTexture );
            icon.setTextureForState( ButtonState.DOWN_AND_SELECTED, mFullScreenExitIconTexture );

            button.defaultIcon = icon;
            button.hasLabelTextRenderer = false;
        }

        /**
         * Time label
         */

        protected function setTimeLabelStyles( label:TimeLabel ):void {
            label.fontStyles = mLightRegularSmallTF.clone();
            label.disabledFontStyles = mLightRegularSmallDisabledTF.clone();
        }

        /**
         * Volume slider
         */

        protected function setVolumeSliderStyles( slider:VolumeSlider ):void {
            slider.direction = Direction.HORIZONTAL;
            slider.trackLayoutMode = TrackLayoutMode.SPLIT;
            slider.showThumb = false;
            slider.minTouchWidth = slider.minTouchWidth = mControlSize;
        }

        protected function setVolumeSliderThumbStyles( thumb:Button ):void {
            thumb.minTouchWidth = thumb.minTouchHeight = mControlSize;
        }

        protected function setVolumeSliderMinimumTrackStyles( track:Button ):void {
            var defaultSkin:ImageLoader = new ImageLoader();
            defaultSkin.scaleContent = false;
            defaultSkin.source = mVolumeSliderMinTrackTexture;
            defaultSkin.height = 18;
            track.defaultSkin = defaultSkin;
            track.hasLabelTextRenderer = false;
        }

        protected function setVolumeSliderMaximumTrackStyles( track:Button ):void {
            var defaultSkin:ImageLoader = new ImageLoader();
            defaultSkin.scaleContent = false;
            defaultSkin.horizontalAlign = HorizontalAlign.RIGHT;
            defaultSkin.source = mVolumeSliderMaxTrackTexture;
            defaultSkin.height = 18;
            track.defaultSkin = defaultSkin;
            track.hasLabelTextRenderer = false;
        }

        /**
         *
         *
         * Shared
         *
         *
         */

        protected function scaleButtonIcon( button:Button, scalar:Number = 1.0 ):void {
            var icon:DisplayObject = button.defaultIcon;
            if( icon ) {
                icon.scaleX = icon.scaleY = scalar;
            }
            var toggleButton:ToggleButton = button as ToggleButton;
            if( toggleButton ) {
                icon = toggleButton.defaultSelectedIcon;
                if( icon ) {
                    icon.scaleX = icon.scaleY = scalar;
                }
            }
        }

        protected function tintButtonIcon( button:Button, color:uint ):void {
            const icon:Image = button.defaultIcon as Image;
            if( icon ) {
                icon.color = color;
            }
        }

        protected function setScrollerStyles( scroller:Scroller ):void {
            scroller.verticalScrollBarFactory = scrollBarFactory;
            scroller.horizontalScrollBarFactory = scrollBarFactory;
            scroller.hasElasticEdges = false;
        }

        protected function setBaseTextInputStyles( input:TextInput ):void {
            input.paddingTop = mSmallPaddingSize >> 1;
            input.paddingLeft = 2.5;
            input.paddingRight = 2.5;

            input.fontStyles = mLightRegularTF.clone();
            input.disabledFontStyles = mLightRegularDisabledTF.clone();

            input.promptFontStyles = mLightRegularTF.clone();
            input.promptDisabledFontStyles = mLightRegularDisabledTF.clone();
        }

        protected function setBaseButtonStyles( button:Button, iconScale:Number = 0.75 ):void {
            button.gap = Number.POSITIVE_INFINITY;
            button.minGap = mSmallPaddingSize;
            button.paddingLeft = button.paddingRight = mRegularPaddingSize;
            button.labelOffsetY = -1;
            /* Adjust the padding if an icon is used */
            if( button.defaultIcon ) {
                if( button.iconPosition == RelativePosition.LEFT ) {
                    button.paddingLeft = mSmallPaddingSize;
                } else if( button.iconPosition == RelativePosition.RIGHT ) {
                    button.paddingRight = mSmallPaddingSize;
                }
            }

            scaleButtonIcon( button, iconScale );

            button.fontStyles = mLightRegularTF.clone();
            button.disabledFontStyles = mLightRegularDisabledTF.clone();
        }

        protected function setBaseCallToActionButtonStyles( button:Button ):void {
            button.padding = 0;
            button.maxHeight = mLargeControlSize;
            button.iconOffsetY = -1;
            button.iconPosition = RelativePosition.TOP;
            button.hasLabelTextRenderer = false;

            scaleButtonIcon( button );

            ActionButtonRadialAnimationManager.getInstance().add( button );
        }

        protected function setBaseDropDownListItemRendererStyles( renderer:BaseDefaultItemRenderer ):FadeImageSkin {
            var skin:FadeImageSkin = new FadeImageSkin( mDropDownListItemRendererUpTexture );
            skin.setTextureForState( ButtonState.DOWN, mDropDownListItemRendererDownTexture );
            skin.width = mControlSize * 2;
            skin.height = mLargeControlSize;
            skin.scale9Grid = BACKGROUND_SCALE9_GRID;
            renderer.defaultSkin = skin;

            renderer.gap = mRegularPaddingSize;
            renderer.itemHasIcon = false;
            renderer.iconPosition = RelativePosition.LEFT;
            renderer.accessoryGap = Number.POSITIVE_INFINITY;
            renderer.minAccessoryGap = mRegularPaddingSize;
            renderer.horizontalAlign = HorizontalAlign.CENTER;
            renderer.accessoryPosition = RelativePosition.RIGHT;
            renderer.paddingTop = 0;

            renderer.fontStyles = mLightRegularTF.clone();
            renderer.disabledFontStyles = mLightRegularDisabledTF.clone();
            renderer.accessoryLabelFontStyles = mLightRegularTF.clone();
            renderer.iconLabelFontStyles = mLightRegularTF.clone();

            return skin;
        }

        /**
         *
         *
         * Font renderers / factories
         *
         *
         */

        protected function textRendererFactory():ITextRenderer {
	        const renderer:TextBlockTextRenderer = new TextBlockTextRenderer();
	        var style:FontStylesSet = new FontStylesSet();
	        style.format = mLightRegularTF.clone();
	        renderer.fontStyles = style;
	        return renderer;
        }

        protected function popUpOverlayFactory():DisplayObject {
            var overlaySkin:Image = new Image( mBackgroundPlainTexture );
            overlaySkin.scale9Grid = BACKGROUND_SCALE9_GRID;
            overlaySkin.alpha = ALPHA_MODAL_OVERLAY;
            return overlaySkin;
        }

        protected function imageLoaderFactory():ImageLoader {
            var image:ImageLoader = new ImageLoader();
            /* Tint the icon to light color since this factory
             * is used for elements with dark background */
            image.color = COLOR_UI_LIGHT;
            return image;
        }

        protected function scrollBarFactory():SimpleScrollBar {
            return new SimpleScrollBar();
        }

        protected function textEditorFactory():ITextEditor {
            return new StageTextTextEditor();
        }

        protected function textAreaTextEditorFactory():StageTextTextEditorViewPort {
            return new StageTextTextEditorViewPort();
        }

        protected function stepperTextEditorFactory():TextBlockTextEditor {
            return new TextBlockTextEditor();
        }

        protected function pageIndicatorNormalSymbolFactory():DisplayObject {
            var symbol:ImageLoader = new ImageLoader();
            symbol.source = mPageIndicatorNormalTexture;
            return symbol;
        }

        protected function pageIndicatorSelectedSymbolFactory():DisplayObject {
            var symbol:ImageLoader = new ImageLoader();
            symbol.source = mPageIndicatorSelectedTexture;
            return symbol;
        }

        override public function dispose():void {
            /* Dispose shared slider textures */
            AnimatedSliderThumb.mUpTexture = null;
            AnimatedSliderThumb.mDownTexture = null;
            AnimatedSliderThumb.mDisabledTexture = null;
            /* Dispose animation managers */
            ButtonRadialAnimationManager.dispose();
            BackButtonRadialAnimationManager.dispose();
            ForwardButtonRadialAnimationManager.dispose();
            ToggleRadialAnimationManager.dispose();
            ActionButtonRadialAnimationManager.dispose();
            AccentQuietButtonRadialAnimationManager.dispose();
            PrimaryQuietButtonRadialAnimationManager.dispose();
            QuietButtonRadialAnimationManager.dispose();
            TabButtonRadialAnimationManager.dispose();
            ListItemRadialAnimationManager.dispose();
            HeaderIconOnlyButtonRadialAnimationManager.dispose();
            PageIndicatorRadialAnimationManager.dispose();
            /* Radial effect pools */
            RadialEffectPool.dispose();
            AccentRadialEffectPool.dispose();
            PrimaryRadialEffectPool.dispose();
            LightRadialEffectPool.dispose();
            ToggleRadialEffectPool.dispose();
            ShadowFilterPool.dispose();
            MaskPool.dispose();

            if( mAtlas ) {
                mAtlas.dispose();
                mAtlas = null;
            }

            super.dispose();
        }

    }

}

/**
 *
 *
 * Animation stuff.
 *
 *
 */

import feathers.controls.Button;
import feathers.controls.ButtonState;
import feathers.controls.Check;
import feathers.controls.ImageLoader;
import feathers.controls.PageIndicator;
import feathers.controls.Radio;
import feathers.controls.TabBar;
import feathers.controls.ToggleButton;
import feathers.controls.ToggleSwitch;
import feathers.core.FeathersControl;
import feathers.core.IFeathersControl;
import feathers.core.IMeasureDisplayObject;
import feathers.core.IStateContext;
import feathers.core.IStateObserver;
import feathers.core.IToggle;
import feathers.core.IValidating;
import feathers.events.FeathersEventType;

import flash.geom.Point;
import flash.geom.Rectangle;
import flash.utils.Dictionary;

import starling.animation.Juggler;
import starling.animation.Transitions;
import starling.core.Starling;
import starling.display.Canvas;
import starling.display.DisplayObject;
import starling.display.DisplayObjectContainer;
import starling.display.Image;
import starling.display.Quad;
import starling.events.Event;
import starling.events.Touch;
import starling.events.TouchEvent;
import starling.events.TouchPhase;
import starling.filters.DropShadowFilter;
import starling.geom.Polygon;
import starling.textures.Texture;

/**
 * Custom ToggleButton for TabBar - changes color of its icon (if exists) when selection state changes.
 */
class CustomTab extends ToggleButton {

    public function CustomTab() {
        super();
    }

    override public function set isSelected( value:Boolean ):void {
        if( defaultIcon && defaultIcon is Image ) {
            Image( defaultIcon ).color = value ? 0xFFFFFF : 0x949599;
        }
        super.isSelected = value;
    }

    override public function set defaultIcon( value:DisplayObject ):void {
        if( value ) {
            value.scaleX = value.scaleY = 0.75;
        }

        super.defaultIcon = value;
    }

}

/**
 * Custom thumb for Slider.
 */
class AnimatedSliderThumb extends Button {

	private var mUpSkin:Image;
	private var mDownSkin:Image;
	private var mDisabledSkin:Image;
	private var mThumbTweenID:uint;
	private var mJuggler:Juggler;

	public static var mUpTexture:Texture;
	public static var mDownTexture:Texture;
	public static var mDisabledTexture:Texture;
	public static var mThumbScale9Grid:Rectangle;

	public function AnimatedSliderThumb():void {
		super();

		mUpSkin = new Image( upTexture );
		mDownSkin = new Image( downTexture );
		mDisabledSkin = new Image( disabledTexture );
		mDownSkin.scale9Grid = mDisabledSkin.scale9Grid = mThumbScale9Grid;

		mDownSkin.width = mDownSkin.height =
				mDisabledSkin.width = mDisabledSkin.height = 25;
	}

	/**
	 * Touch handler
	 */
	private function onTouch( event:TouchEvent ):void {
		const touch:Touch = event.getTouch( this );
		if( touch ) {
			/* Touch BEGAN */
			if( touch.phase == TouchPhase.BEGAN ) {
				if( mThumbTweenID > 0 ) {
					mJuggler.removeByID( mThumbTweenID );
				}
				mThumbTweenID = mJuggler.tween( mUpSkin, 0.2, {
					scale     : 1,
					transition: Transitions.EASE_OUT,
					onComplete: nullifyTween
				} );
			}
			/* Touch ENDED */
			else if( touch.phase == TouchPhase.ENDED ) {
				if( mThumbTweenID > 0 ) {
					mJuggler.removeByID( mThumbTweenID );
				}
				mThumbTweenID = mJuggler.tween( mUpSkin, 0.3, {
					scale     : 0.7,
					transition: Transitions.EASE_OUT,
					onComplete: nullifyTween
				} );
			}
		}
	}

	private function nullifyTween():void {
		mThumbTweenID = 0;
	}

	override protected function initialize():void {
		super.initialize();

		mUpSkin.alignPivot();
		addChild( mUpSkin );

		mDownSkin.alignPivot();
		mUpSkin.x = mDownSkin.x = mDownSkin.width * 0.5;
		mUpSkin.y = mDownSkin.y = mDownSkin.height * 0.5;
		defaultSkin = mDownSkin;

		mDisabledSkin.alignPivot();
		disabledSkin = mDisabledSkin;

		mJuggler = Starling.juggler;

		addEventListener( TouchEvent.TOUCH, onTouch );
	}

	override protected function scaleSkin():void {
		if( currentSkin ) {
			currentSkin.x = 12.5;
			currentSkin.y = 12.5;
			if( this.currentSkin is IValidating ) {
				IValidating( this.currentSkin ).validate();
			}
		}
	}

	override protected function draw():void {
		super.draw();

		if( isInvalid( INVALIDATION_FLAG_ALL ) ) {
			mUpSkin.scale = 0.7;
		}
	}

	override public function dispose():void {
		removeChildren();
		mJuggler = null;
		mUpSkin = null;
		mDownSkin = null;
		mDisabledSkin = null;
		/* Textures are disposes by the theme's dispose method  */

		super.dispose();
	}

	/**
	 * Methods to provide textures for the thumb. May be overridden for different look.
	 */

	protected function get upTexture():Texture {
		return mUpTexture;
	}

	protected function get downTexture():Texture {
		return mDownTexture;
	}

	protected function get disabledTexture():Texture {
		return mDisabledTexture;
	}

}

/**
 * Custom thumb for SeekSlider.
 */
class AnimatedSeekSliderThumb extends AnimatedSliderThumb {

    public static var mUpTexture:Texture;
    public static var mDownTexture:Texture;
    public static var mDisabledTexture:Texture;

    override protected function get upTexture():Texture {
        return mUpTexture;
    }

    override protected function get downTexture():Texture {
        return mDownTexture;
    }

    override protected function get disabledTexture():Texture {
        return mDisabledTexture;
    }
}

/**
 * Base animation manager handles displaying of radial effect and object's mask.
 */
class BaseRadialAnimationManager {

    private static var HELPER_POINT:Point;

    protected static var mJuggler:Juggler;

    protected var mEffectsMap:Dictionary;
    protected var mPendingTriggerMap:Dictionary;

    public function BaseRadialAnimationManager():void {
        if( !HELPER_POINT ) {
            HELPER_POINT = new Point();
        }

        mJuggler = Starling.juggler;
        mEffectsMap = new Dictionary( true );
        mPendingTriggerMap = new Dictionary( true );
    }

    public function add( object:FeathersControl ):void {
        if( !object ) throw new ArgumentError( "Parameter object cannot be null." );

        object.addEventListener( TouchEvent.TOUCH, onTouch );
    }

    protected function onTouchBegan( object:FeathersControl, touchLocation:Point ):void {
    }

    protected function onTouchMoved( object:FeathersControl, touchLocation:Point ):void {
    }

    protected function onTouchEnded( object:FeathersControl, touchLocation:Point ):void {
        /* Event.TRIGGERED is dispatched before touch ENDED phase so we
         * check whether the trigger event really occurred for this object */
        if( object in mPendingTriggerMap ) {
            delete mPendingTriggerMap[object];

            const radialEffect:Image = getRadialEffect();
            radialEffect.x = touchLocation.x;
            radialEffect.y = touchLocation.y;

            const mask:DisplayObject = getMaskForObject( object );
            radialEffect.mask = mask;
            object.addChild( mask );
            object.addChildAt( radialEffect, 1 );

            const effectWidth:Number = (object.width < 200) ? object.width : 200;
            const prevScale:Number = radialEffect.scaleX;
            radialEffect.width = effectWidth;
            const finalScale:Number = radialEffect.scaleX;
            radialEffect.scaleX = prevScale;

            mJuggler.tween( radialEffect, 0.7, {
                alpha         : 0,
                transition    : Transitions.EASE_OUT,
                onComplete    : recycleObjects,
                onCompleteArgs: [radialEffect, mask]
            } );
            mJuggler.tween( radialEffect, 0.5, {
                scaleX    : finalScale,
                scaleY    : finalScale,
                transition: Transitions.EASE_OUT
            } );
        }
    }

    protected function onTriggered( event:Event ):void {
        mPendingTriggerMap[event.currentTarget] = true;
    }

    protected function recycleObjects( radialEffect:Image, mask:DisplayObject ):void {
        radialEffect.mask = null;
        radialEffect.removeFromParent();
        mask.removeFromParent();
        recycleRadialEffect( radialEffect );
        recycleMask( mask );
    }

    private function onTouch( event:TouchEvent ):void {
        const target:FeathersControl = FeathersControl( event.currentTarget );
        if( !target.isEnabled ) return;
        const touch:Touch = event.getTouch( target );
        if( touch ) {
            touch.getLocation( target, HELPER_POINT );
            if( touch.phase == TouchPhase.BEGAN ) {
                onTouchBegan( target, HELPER_POINT );
            } else if( touch.phase == TouchPhase.ENDED ) {
                onTouchEnded( target, HELPER_POINT );
            } else if( touch.phase == TouchPhase.MOVED ) {
                onTouchMoved( target, HELPER_POINT );
            }
        }
    }

    protected function recycleRadialEffect( radialEffect:Image ):void {
        RadialEffectPool.getInstance().push( radialEffect );
    }

    protected function getRadialEffect():Image {
        return RadialEffectPool.getInstance().pop();
    }

    [Abstract]
    protected function getMaskForObject( object:DisplayObjectContainer ):DisplayObject {
        throw new Error( "Method getMaskForObject is abstract and must be overridden." );
    }

    [Abstract]
    protected function recycleMask( mask:DisplayObject ):void {
        throw new Error( "Method recycleMask is abstract and must be overridden." );
    }

    public function dispose():void {
        HELPER_POINT = null;
        mJuggler = null;
        mEffectsMap = null;
    }

}

/**
 * Subclass of base animation manager. Adds shadow to touched objects.
 */
class ButtonRadialAnimationManager extends BaseRadialAnimationManager {

	private var mShadowTween:uint;
	protected var mSubclassInit:Boolean;

	/* Singleton stuff */
	private static var mCanInitialize:Boolean;
	private static var mInstance:ButtonRadialAnimationManager;

	public function ButtonRadialAnimationManager() {
		super();

		if( !mSubclassInit && !mCanInitialize ) throw new Error( "ButtonRadialAnimationManager is a singleton, use getInstance()." );
	}

	public static function getInstance():ButtonRadialAnimationManager {
		if( !mInstance ) {
			mCanInitialize = true;
			mInstance = new ButtonRadialAnimationManager();
			mCanInitialize = false;
		}
		return mInstance;
	}

    override public function add( object:FeathersControl ):void{
        super.add(object);

        object.addEventListener( Event.TRIGGERED, onTriggered );
        object.addEventListener( FeathersEventType.STATE_CHANGE, onStateChanged );
    }

    private function onStateChanged( event:Event ):void {
        var state:String = IStateContext( event.currentTarget ).currentState;
        if( state == ButtonState.HOVER || state == ButtonState.HOVER_AND_SELECTED ) return;

        var object:FeathersControl = FeathersControl( event.currentTarget );
        if( state == ButtonState.DOWN || state == ButtonState.DOWN_AND_SELECTED ) {
            showShadow( object );
        } else if( state == ButtonState.UP || state == ButtonState.UP_AND_SELECTED ) {
            hideShadow( object );
        }
    }

    private function showShadow( object:FeathersControl ):void {
        /* Pop the shadow filter from the pool or use the button's current shadow filter */
        var shadowFilter:DropShadowFilter = ShadowFilterPool.pop();
        if( mShadowTween > 0 && object.filter is DropShadowFilter ) {
            mJuggler.removeByID( mShadowTween );
            mShadowTween = 0;
            shadowFilter = DropShadowFilter( object.filter );
        } else {
            shadowFilter = ShadowFilterPool.pop();
        }
        object.filter = shadowFilter;

        /* Tween the shadow */
        mJuggler.tween( shadowFilter, 0.6, {
            blur      : 2,
            distance  : 2,
            transition: Transitions.EASE_OUT
        } );
    }

    private function hideShadow( object:FeathersControl ):void {
        /* The shadow was removed earlier or is being removed right now, no need to do anything */
        if( object.filter === null || mShadowTween != 0 ) return;

        /* Store ref to tween so it can be removed if the button is
         * tapped again before the shadow fades out completely */
        mShadowTween = mJuggler.tween( object.filter, 0.4, {
            blur          : 0,
            distance      : 0,
            transition    : Transitions.EASE_OUT,
            onComplete    : recycleFilter,
            onCompleteArgs: [object, object.filter]
        } );
    }

	/**
	 * Recycles object's shadow filter
	 */
	private function recycleFilter( object:DisplayObjectContainer, shadowFilter:DropShadowFilter ):void {
		ShadowFilterPool.push( shadowFilter );
		object.filter = null;
		mShadowTween = 0;
	}

	override protected function getMaskForObject( object:DisplayObjectContainer ):DisplayObject {
		const mask:Quad = MaskPool.pop();
		mask.width = object.width - 4;
		mask.height = object.height - 4;
		mask.x = 2;
		mask.y = 1;
		return mask;
	}

	override protected function recycleMask( mask:DisplayObject ):void {
		MaskPool.push( Quad( mask ) );
	}

	override public function dispose():void {
		super.dispose();
		mShadowTween = 0;
	}

	public static function dispose():void {
		if( mInstance ) {
			mInstance.dispose();
			mInstance = null;
		}
	}

}

/**
 * Subclass of button animation manager. Provides different mask.
 */
class BackButtonRadialAnimationManager extends ButtonRadialAnimationManager {

    /* Singleton stuff */
    private static var mCanInitialize:Boolean;
    private static var mInstance:BackButtonRadialAnimationManager;

    public function BackButtonRadialAnimationManager() {
        mSubclassInit = true;
        super();

        if( !mCanInitialize ) throw new Error( "BackButtonRadialAnimationManager is a singleton, use getInstance()." );
    }

    public static function getInstance():BackButtonRadialAnimationManager {
        if( !mInstance ) {
            mCanInitialize = true;
            mInstance = new BackButtonRadialAnimationManager();
            mCanInitialize = false;
        }
        return mInstance;
    }

    override protected function getMaskForObject( object:DisplayObjectContainer ):DisplayObject {
        /* Draw polygon mask to cover the back button */
        const mask:Canvas = new Canvas();
        mask.beginFill( 0 );
        mask.drawPolygon( new Polygon( [
            0,
            17,
            17.5,
            0,
            object.width - 3.5,
            0,
            object.width - 3.5,
            object.height - 4,
            17.5,
            object.height - 4
        ] ) );
        mask.x = 1.5;
        mask.y = 1;
        return mask;
    }

    override protected function recycleMask( mask:DisplayObject ):void {
        Canvas( mask ).dispose();
    }

    public static function dispose():void {
        if( mInstance ) {
            mInstance.dispose();
            mInstance = null;
        }
    }

}

/**
 * Subclass of button animation manager. Provides different mask.
 */
class ForwardButtonRadialAnimationManager extends ButtonRadialAnimationManager {

    /* Singleton stuff */
    private static var mCanInitialize:Boolean;
    private static var mInstance:ForwardButtonRadialAnimationManager;

    public function ForwardButtonRadialAnimationManager() {
        mSubclassInit = true;
        super();

        if( !mCanInitialize ) throw new Error( "ForwardButtonRadialAnimationManager is a singleton, use getInstance()." );
    }

    public static function getInstance():ForwardButtonRadialAnimationManager {
        if( !mInstance ) {
            mCanInitialize = true;
            mInstance = new ForwardButtonRadialAnimationManager();
            mCanInitialize = false;
        }
        return mInstance;
    }

    override protected function getMaskForObject( object:DisplayObjectContainer ):DisplayObject {
        const objWidth:Number = object.width;
        const objHeight:Number = object.height;
        /* Draw polygon mask to cover the forward button */
        const mask:Canvas = new Canvas();
        mask.beginFill( 0 );
        mask.drawPolygon( new Polygon( [
            0,
            0,
            objWidth - 19,
            0,
            objWidth - 4,
            17.5,
            objWidth - 19,
            objHeight - 4,
            0,
            objHeight - 4
        ] ) );
        mask.x = 1.5;
        mask.y = 1;
        return mask;
    }

    override protected function recycleMask( mask:DisplayObject ):void {
        Canvas( mask ).dispose();
    }

    public static function dispose():void {
        if( mInstance ) {
            mInstance.dispose();
            mInstance = null;
        }
    }

}

/**
 * Subclass of base animation manager.
 */
class QuietButtonRadialAnimationManager extends BaseRadialAnimationManager {

    protected var mSubclassInit:Boolean;

    /* Singleton stuff */
    private static var mCanInitialize:Boolean;
    private static var mInstance:QuietButtonRadialAnimationManager;

    public function QuietButtonRadialAnimationManager() {
        super();

        if( !mSubclassInit && !mCanInitialize ) throw new Error( "QuietButtonRadialAnimationManager is a singleton, use getInstance()." );
    }

    public static function getInstance():QuietButtonRadialAnimationManager {
        if( !mInstance ) {
            mCanInitialize = true;
            mInstance = new QuietButtonRadialAnimationManager();
            mCanInitialize = false;
        }
        return mInstance;
    }

    override public function add( object:FeathersControl ):void {
        super.add(object);

        object.addEventListener( Event.TRIGGERED, onTriggered );
    }

    override protected function getMaskForObject( object:DisplayObjectContainer ):DisplayObject {
        const mask:Quad = MaskPool.pop();
        mask.width = object.width - 2;
        mask.height = object.height - 2;
        mask.x = 1;
        mask.y = 1.5;
        return mask;
    }

    override protected function recycleMask( mask:DisplayObject ):void {
        MaskPool.push( Quad( mask ) );
    }

    public static function dispose():void {
        if( mInstance ) {
            mInstance.dispose();
            mInstance = null;
        }
    }

}

/**
 * Subclass of quiet button animation manager. Provides primary-colored radial effect texture.
 */
class PrimaryQuietButtonRadialAnimationManager extends QuietButtonRadialAnimationManager {

    /* Singleton stuff */
    private static var mCanInitialize:Boolean;
    private static var mInstance:PrimaryQuietButtonRadialAnimationManager;

    public function PrimaryQuietButtonRadialAnimationManager() {
        mSubclassInit = true;
        super();

        if( !mCanInitialize ) throw new Error( "PrimaryQuietButtonRadialAnimationManager is a singleton, use getInstance()." );
    }

    public static function getInstance():PrimaryQuietButtonRadialAnimationManager {
        if( !mInstance ) {
            mCanInitialize = true;
            mInstance = new PrimaryQuietButtonRadialAnimationManager();
            mCanInitialize = false;
        }
        return mInstance;
    }

    /**
     * Overrides radial effect methods to provide primary-color texture.
     */

    override protected function recycleRadialEffect( radialEffect:Image ):void {
        // PrimaryRadialEffectPool.getInstance().push( radialEffect );
        // Not reused - Alert disposes this effect which causes problems when reused
    }

    override protected function getRadialEffect():Image {
        return PrimaryRadialEffectPool.getInstance().pop();
    }

    public static function dispose():void {
        if( mInstance ) {
            mInstance.dispose();
            mInstance = null;
        }
    }

}

/**
 * Subclass of quiet button animation manager. Provides accent-colored radial effect texture.
 */
class AccentQuietButtonRadialAnimationManager extends QuietButtonRadialAnimationManager {

    /* Singleton stuff */
    private static var mCanInitialize:Boolean;
    private static var mInstance:AccentQuietButtonRadialAnimationManager;

    public function AccentQuietButtonRadialAnimationManager() {
        mSubclassInit = true;
        super();

        if( !mCanInitialize ) throw new Error( "AccentQuietButtonRadialAnimationManager is a singleton, use getInstance()." );
    }

    public static function getInstance():AccentQuietButtonRadialAnimationManager {
        if( !mInstance ) {
            mCanInitialize = true;
            mInstance = new AccentQuietButtonRadialAnimationManager();
            mCanInitialize = false;
        }
        return mInstance;
    }

    /**
     * Overrides radial effect methods to provide accent-color texture.
     */

    override protected function recycleRadialEffect( radialEffect:Image ):void {
        AccentRadialEffectPool.getInstance().push( radialEffect );
    }

    override protected function getRadialEffect():Image {
        return AccentRadialEffectPool.getInstance().pop();
    }

    public static function dispose():void {
        if( mInstance ) {
            mInstance.dispose();
            mInstance = null;
        }
    }

}

/**
 * Subclass of base animation manager. Uses circular mask and lighter radial effect texture.
 */
class HeaderIconOnlyButtonRadialAnimationManager extends QuietButtonRadialAnimationManager {

    /* Singleton stuff */
    private static var mCanInitialize:Boolean;
    private static var mInstance:HeaderIconOnlyButtonRadialAnimationManager;

    public function HeaderIconOnlyButtonRadialAnimationManager() {
        mSubclassInit = true;
        super();

        if( !mCanInitialize ) throw new Error( "HeaderIconOnlyButtonRadialAnimationManager is a singleton, use getInstance()." );
    }

    public static function getInstance():HeaderIconOnlyButtonRadialAnimationManager {
        if( !mInstance ) {
            mCanInitialize = true;
            mInstance = new HeaderIconOnlyButtonRadialAnimationManager();
            mCanInitialize = false;
        }
        return mInstance;
    }

    override public function add( object:FeathersControl ):void {
        super.add(object);

        /* We don't want the animation to start on TRIGGERED event,
         * instead we want it to happen on touch BEGAN */
        object.removeEventListener( Event.TRIGGERED, onTriggered );
    }

    override protected function onTouchBegan( object:FeathersControl, touchLocation:Point ):void {
        const radialEffect:Image = getRadialEffect();
        radialEffect.x = touchLocation.x;
        radialEffect.y = touchLocation.y;

        const objWidth:int = object.width;
        const objHeight:int = object.height;
        const finalX:int = objWidth * 0.5;
        const finalY:int = objHeight * 0.5;

        /* The closer the touch is to the sides of the object the faster the radial animation is */
        var touchPositionRatio:Number = (touchLocation.x / objWidth) - 0.5;   // Gives values from -0.5 to 0.5
        touchPositionRatio = (touchPositionRatio < 0) ? -touchPositionRatio : touchPositionRatio;   // Absolute value
        const tweenDurationModifier:Number = 1.0 - touchPositionRatio;

        /* Calculate the radial effect final scale */
        radialEffect.width = objWidth * 1.5;
        const finalScale:Number = radialEffect.scaleX;
        radialEffect.scaleX = 0;

        /* Create mask for the radial effect */
        const mask:DisplayObject = getMaskForObject( object );
        radialEffect.mask = mask;
        object.addChild( mask );
        object.addChildAt( radialEffect, 1 );

        /* Tween the radial effect */
        var tweenDuration:Number = finalScale;
        tweenDuration = (tweenDuration < 0.8) ? 0.8 : ((tweenDuration > 2.5) ? 2.5 : tweenDuration);
        mJuggler.removeTweens( radialEffect );
        mJuggler.tween( radialEffect, tweenDuration * tweenDurationModifier, {
            delay     : 0.15,
            scaleX    : finalScale,
            scaleY    : finalScale,
            x         : finalX,
            y         : finalY,
            transition: Transitions.EASE_OUT
        } );

        mEffectsMap[object] = {effect: radialEffect, mask: mask};
    }

    /**
     * Overridden function removes/adds effects depending on the object's focus.
     */
    override protected function onTouchMoved( object:FeathersControl, touchLocation:Point ):void {
        const isInBounds:Boolean = object.contains( object.hitTest( touchLocation ) );
        const isEffectActive:Boolean = object in mEffectsMap;
        /* If we are no longer touching the object then remove the effect (if it is active) */
        if( !isInBounds ) {
            if( isEffectActive ) {
                onTouchEnded( object, touchLocation );
            }
        }
        /* Add the effect (if it is not active) once we are touching the object again */
        else if( !isEffectActive ) {
            onTouchBegan( object, touchLocation );
        }
    }

    override protected function onTouchEnded( object:FeathersControl, touchLocation:Point ):void {
        /* Effect was removed earlier (e.g. by moving out of the object's bounds), no need to do anything */
        if( !(object in mEffectsMap) ) return;

        const radialEffect:Image = mEffectsMap[object].effect;
        const mask:DisplayObject = mEffectsMap[object].mask;

        const prevScale:Number = radialEffect.scaleX;
        radialEffect.width = object.width * 1.5;
        const finalScale:Number = radialEffect.scaleX;
        radialEffect.scaleX = prevScale;

        if( radialEffect.scaleX == 0 ) {
            mJuggler.removeTweens( radialEffect );
            recycleObjects( radialEffect, mask );
        } else {
            mJuggler.tween( radialEffect, 0.7, {
                alpha         : 0,
                scaleX        : finalScale,
                scaleY        : finalScale,
                transition    : Transitions.EASE_OUT,
                onComplete    : recycleObjects,
                onCompleteArgs: [radialEffect, mask]
            } );
        }

        delete mEffectsMap[object];
    }

    override protected function getMaskForObject( object:DisplayObjectContainer ):DisplayObject {
        const radius:Number = object.width * 0.5;
        /* Draw circular mask to cover the button */
        const mask:Canvas = new Canvas();
        mask.beginFill( 0 );
        mask.drawCircle( radius, radius, radius );
        return mask;
    }

    override protected function recycleMask( mask:DisplayObject ):void {
        Canvas( mask ).dispose();
    }

    /**
     * Overrides radial effect methods to provide lighter texture.
     */

    override protected function recycleRadialEffect( radialEffect:Image ):void {
        LightRadialEffectPool.getInstance().push( radialEffect );
    }

    override protected function getRadialEffect():Image {
        return LightRadialEffectPool.getInstance().pop();
    }

    public static function dispose():void {
        if( mInstance ) {
            mInstance.dispose();
            mInstance = null;
        }
    }

}

/**
 * Subclass of button animation manager. Provides circular mask.
 */
class ActionButtonRadialAnimationManager extends ButtonRadialAnimationManager {

    /* Singleton stuff */
    private static var mCanInitialize:Boolean;
    private static var mInstance:ActionButtonRadialAnimationManager;

    public function ActionButtonRadialAnimationManager() {
        mSubclassInit = true;
        super();

        if( !mCanInitialize ) throw new Error( "ActionButtonRadialAnimationManager is a singleton, use getInstance()." );
    }

    public static function getInstance():ActionButtonRadialAnimationManager {
        if( !mInstance ) {
            mCanInitialize = true;
            mInstance = new ActionButtonRadialAnimationManager();
            mCanInitialize = false;
        }
        return mInstance;
    }

    override protected function getMaskForObject( object:DisplayObjectContainer ):DisplayObject {
        const radius:Number = (object.width - 2) * 0.5;
        /* Draw circular mask to cover the button */
        const mask:Canvas = new Canvas();
        mask.beginFill( 0 );
        mask.drawCircle( radius, radius, radius );
        mask.x = 1;
        return mask;
    }

    override protected function recycleMask( mask:DisplayObject ):void {
        Canvas( mask ).dispose();
    }

    public static function dispose():void {
        if( mInstance ) {
            mInstance.dispose();
            mInstance = null;
        }
    }

}

/**
 * Subclass of base animation manager. Radial effect's texture depends on the selected
 * property of IToggle component.
 */
class ToggleRadialAnimationManager extends BaseRadialAnimationManager {

    private var mRadialTween:uint;

    /* Singleton stuff */
    private static var mCanInitialize:Boolean;
    private static var mInstance:ToggleRadialAnimationManager;

    public function ToggleRadialAnimationManager() {
        super();

        if( !mCanInitialize ) throw new Error( "ToggleRadialAnimationManager is a singleton, use getInstance()." );
    }

    public static function getInstance():ToggleRadialAnimationManager {
        if( !mInstance ) {
            mCanInitialize = true;
            mInstance = new ToggleRadialAnimationManager();
            mCanInitialize = false;
        }
        return mInstance;
    }

    override protected function onTouchBegan( object:FeathersControl, touchLocation:Point ):void {
        /* Proceed only if the object implements IToggle interface */
        if( object is IToggle ) {
            const toggle:IToggle = IToggle( object );
            /* In the case of ToggleSwitch, the radial effect is
             * added to its thumb, not the ToggleSwitch container */
            var targetObject:DisplayObjectContainer = getTargetObject( object );
            /* Add radial effect */
            const radialEffect:Image = ToggleRadialEffectPool.pop( toggle.isSelected );
            radialEffect.scaleX = radialEffect.scaleY = 0.8;
            targetObject.addChildAt( radialEffect, 0 );
            /* Radial effect is centered to ToggleSwitch's thumb or Radio/Check's skin icon */
            positionRadialEffect( targetObject, radialEffect );

            mRadialTween = mJuggler.tween( radialEffect, 0.25, {
                scaleX    : 1,
                scaleY    : 1,
                alpha     : 1.0,
                transition: Transitions.EASE_OUT
            } );

            mEffectsMap[targetObject] = radialEffect;
        } else {
            trace( "Warning: ToggleRadialAnimationManager is only applicable to IToggle components." );
        }
    }

    /**
     * Overridden function removes/adds effects depending on the object's focus.
     */
    override protected function onTouchMoved( object:FeathersControl, touchLocation:Point ):void {
        var targetObject:DisplayObjectContainer = getTargetObject( object );

        const isInBounds:Boolean = object.contains( object.hitTest( touchLocation ) );
        const isEffectActive:Boolean = targetObject in mEffectsMap;
        /* If we are no longer touching the object then remove the effect (if it is active) */
        if( !isInBounds ) {
            if( isEffectActive ) {
                onTouchEnded( object, touchLocation );
            }
        }
        /* Add the effect (if it is not active) once we are touching the object again */
        else if( !isEffectActive ) {
            onTouchBegan( object, touchLocation );
        }
    }

    override protected function onTouchEnded( object:FeathersControl, touchLocation:Point ):void {
        var targetObject:DisplayObjectContainer = getTargetObject( object );

        /* The effect was removed earlier, no need to do anything */
        if( !(targetObject in mEffectsMap) ) return;

        const radialEffect:Image = mEffectsMap[targetObject];

        if( mRadialTween > 0 ) {
            mJuggler.removeByID( mRadialTween );
            mRadialTween = 0;
        }
        mJuggler.tween( radialEffect, 0.75, {
            scaleX        : 0.5,
            scaleY        : 0.5,
            alpha         : 0,
            transition    : Transitions.EASE_OUT,
            onComplete    : recycleEffect,
            onCompleteArgs: [radialEffect]
        } );

        delete mEffectsMap[targetObject];
    }

    private function recycleEffect( radialEffect:Image ):void {
        radialEffect.removeFromParent();
        ToggleRadialEffectPool.push( radialEffect );
    }

    /**
     * The radial effect is not added to ToggleSwitch container but its thumb.
     * This method retrieves the ToggleSwitch's thumb, or returns the original object.
     */
    private function getTargetObject( object:DisplayObjectContainer ):DisplayObjectContainer {
        var targetObject:DisplayObjectContainer = object;
        if( object is ToggleSwitch ) {
            const length:uint = object.numChildren;
            for( var i:uint = 0; i < length; i++ ) {
                const child:DisplayObject = object.getChildAt( i );
                if( child is ToggleButton ) {
                    targetObject = DisplayObjectContainer( child );
                    break;
                }
            }
        }
        return targetObject;
    }

    private function positionRadialEffect( targetObject:DisplayObjectContainer, radialEffect:Image ):void {
        /* Check or Radio component */
        if( targetObject is Check || targetObject is Radio ) {
            /* Radial effect must be centered with the Check/Radio skin (icon), not the entire component */
            radialEffect.x = 10;  // 40 is width of the icon
            /* Get the Check/Radio icon's position (for some reason it seems to be offset by a pixel in some cases)*/
            const iconIndex:int = targetObject.numChildren - 2;
            if( iconIndex >= 0 ) {
                const icon:DisplayObject = targetObject.getChildAt( iconIndex );
                radialEffect.x += icon.x;
                radialEffect.y += icon.y;
            }
        }
        /* ToggleSwitch component */
        else {
            radialEffect.x = targetObject.width * 0.5;
        }
        radialEffect.y = targetObject.height * 0.5;
    }

    public static function dispose():void {
        if( mInstance ) {
            mInstance.dispose();
            mInstance = null;
        }
    }

}

/**
 * Subclass of base animation manager.
 */
class ListItemRadialAnimationManager extends BaseRadialAnimationManager {

    /* Singleton stuff */
    private static var mCanInitialize:Boolean;
    private static var mInstance:ListItemRadialAnimationManager;

    public function ListItemRadialAnimationManager() {
        super();

        if( !mCanInitialize ) throw new Error( "ListItemRadialAnimationManager is a singleton, use getInstance()." );
    }

    public static function getInstance():ListItemRadialAnimationManager {
        if( !mInstance ) {
            mCanInitialize = true;
            mInstance = new ListItemRadialAnimationManager();
            mCanInitialize = false;
        }
        return mInstance;
    }

    override public function add( object:FeathersControl ):void {
        super.add(object);

        object.addEventListener( Event.TRIGGERED, onTriggered );
    }

    override protected function getRadialEffect():Image {
        return LightRadialEffectPool.getInstance().pop();
    }

    override protected function recycleRadialEffect( radialEffect:Image ):void {
        LightRadialEffectPool.getInstance().push( radialEffect );
    }

    override protected function getMaskForObject( object:DisplayObjectContainer ):DisplayObject {
        const mask:Quad = MaskPool.pop();
        mask.width = object.width;
        mask.height = object.height;
        mask.x = mask.y = 0;
        return mask;
    }

    override protected function recycleMask( mask:DisplayObject ):void {
        MaskPool.push( Quad( mask ) );
    }

    public static function dispose():void {
        if( mInstance ) {
            mInstance.dispose();
            mInstance = null;
        }
    }

}

/**
 * Subclass of base animation manager. Provides lighter radial effect texture.
 */
class TabButtonRadialAnimationManager extends BaseRadialAnimationManager {

    /* Singleton stuff */
    private static var mCanInitialize:Boolean;
    private static var mInstance:TabButtonRadialAnimationManager;

    public function TabButtonRadialAnimationManager() {
        super();

        if( !mCanInitialize ) throw new Error( "TabButtonRadialAnimationManager is a singleton, use getInstance()." );
    }

    public static function getInstance():TabButtonRadialAnimationManager {
        if( !mInstance ) {
            mCanInitialize = true;
            mInstance = new TabButtonRadialAnimationManager();
            mCanInitialize = false;
        }
        return mInstance;
    }

    override public function add( object:FeathersControl ):void {
        super.add(object);

        object.addEventListener( Event.TRIGGERED, onTriggered );
    }

    override protected function recycleRadialEffect( radialEffect:Image ):void {
        LightRadialEffectPool.getInstance().push( radialEffect );
    }

    override protected function getRadialEffect():Image {
        return LightRadialEffectPool.getInstance().pop();
    }

    override protected function getMaskForObject( object:DisplayObjectContainer ):DisplayObject {
        const tabBar:TabBar = TabBar( object.parent );
        const mask:Quad = MaskPool.pop();
        mask.width = object.width;
        mask.height = object.height - 2;
        mask.x = 0;
        /* Position the mask depending on the shadow's direction */
        mask.y = tabBar.styleNameList.contains( "material-deep-grey-amber-mobile-tab-bar-shadow-bottom" ) ? 0 : 2;
        return mask;
    }

    override protected function recycleMask( mask:DisplayObject ):void {
        MaskPool.push( Quad( mask ) );
    }

    public static function dispose():void {
        if( mInstance ) {
            mInstance.dispose();
            mInstance = null;
        }
    }

}

/**
 * Class taking care of animating selected tab border.
 */
class TabBarSelectionAnimationManager {

    protected static var mJuggler:Juggler;

    public static function add( tabBar:TabBar ):void {
        if( !mJuggler ) {
            mJuggler = Starling.juggler;
        }

        /* Selection border has not yet been added to the tab bar, wait for its creation */
        if( !tabBar.isCreated ) {
            tabBar.addEventListener( FeathersEventType.CREATION_COMPLETE, onCreationComplete );
        }
        /* Selection border has been added, tab bar's style could have changed, reposition the border */
        else {
            mJuggler.delayCall( positionSelectionBorder, 0.05, tabBar );
        }
    }

    private static function onCreationComplete( event:Event ):void {
        const tabBar:TabBar = TabBar( event.currentTarget );
        tabBar.removeEventListener( FeathersEventType.CREATION_COMPLETE, onCreationComplete );

        /* Has to be delayed because the size of the tabs is being
         * distributed and their size is not valid in this handler */
        mJuggler.delayCall( positionSelectionBorder, 0.05, tabBar );
    }

    private static function positionSelectionBorder( tabBar:TabBar ):void {
        tabBar.selectionSkin.y = tabBar.styleNameList.contains( "material-deep-grey-amber-mobile-tab-bar-shadow-bottom" ) ? tabBar.height - 3 : 0;
        tabBar.selectionSkin.alpha = 1;
    }

}

/**
 * Class taking care of animating radial effect for page indicator's symbols.
 */
class PageIndicatorRadialAnimationManager {

    public static var mSelectedSymbolTexture:Texture;

    public static function add( object:PageIndicator ):void {
        object.addEventListener( Event.CHANGE, onChange );
    }

    private static function onChange( event:Event ):void {
        /* Has to be delayed so that the selected symbol's texture gets updated */
        Starling.juggler.delayCall( delayEffect, 0.05, event.currentTarget );
    }

    private static function delayEffect( object:PageIndicator ):void {
        /* Add radial effect */
        const radialEffect:Image = ToggleRadialEffectPool.pop( true );
        radialEffect.scaleX = radialEffect.scaleY = 0.7;
        object.addChild( radialEffect );
        /* Select the correct PageIndicator's symbol */
        positionRadialEffect( object, radialEffect );

        radialEffect.alpha = 1;
        Starling.juggler.tween( radialEffect, 1.0, {
            scaleX        : 1,
            scaleY        : 1,
            alpha         : 0,
            transition    : Transitions.EASE_OUT,
            onComplete    : recycleEffect,
            onCompleteArgs: [radialEffect]
        } );
    }

    private static function recycleEffect( radialEffect:Image ):void {
        radialEffect.removeFromParent();
        ToggleRadialEffectPool.push( radialEffect );
    }

    private static function positionRadialEffect( object:DisplayObjectContainer, radialEffect:Image ):void {
        var symbol:DisplayObject = null;
        /* The order of children does not match the order in which they are shown,
         * thus we need to find the child with the correct texture (the selected one) */
        const length:uint = object.numChildren;
        for( var i:uint = 0; i < length; i++ ) {
            const imageLoader:ImageLoader = object.getChildAt( i ) as ImageLoader;
            if( imageLoader && imageLoader.source == mSelectedSymbolTexture ) {
                symbol = imageLoader;
            }
        }
        radialEffect.x = symbol.x + (symbol.width * 0.5);
        radialEffect.y = (object.height - 1) * 0.5;
    }

    public static function dispose():void {
        mSelectedSymbolTexture = null;
    }

}

/**
 *
 *
 * Object pools
 *
 *
 */

class BaseRadialEffectPool {

    protected var mPool:Vector.<Image>;

    public function BaseRadialEffectPool() {
        mPool = new <Image>[];
    }

    public function pop():Image {
        var radialEffect:Image;
        if( mPool.length > 0 ) {
            radialEffect = mPool.pop();
        } else {
            radialEffect = new Image( getRadialEffectTexture() );
        }
        radialEffect.scaleX = radialEffect.scaleY = 0;
        radialEffect.alignPivot();
        radialEffect.touchable = false;
        radialEffect.alpha = 1;
        return radialEffect;
    }

    public function push( object:Image ):void {
        if( mPool.indexOf( object ) < 0 ) {
            mPool[mPool.length] = object;
        }
    }

    public function dispose():void {
        if( mPool ) {
            const length:uint = mPool.length;
            for( var i:uint = 0; i < length; i++ ) {
                mPool[i].dispose();
            }
            mPool = null;
        }
    }

    [Abstract]
    protected function getRadialEffectTexture():Texture {
        throw new Error( "Method getRadialEffectTexture is abstract and must be overridden." );
    }

}

class RadialEffectPool extends BaseRadialEffectPool {

    public static var mRadialEffectTexture:Texture; // Provided by theme

    /* Singleton stuff */
    private static var mCanInitialize:Boolean;
    private static var mInstance:RadialEffectPool;

    public function RadialEffectPool() {
        super();

        if( !mCanInitialize ) throw new Error( "RadialEffectPool is a singleton, use getInstance()." );
    }

    public static function getInstance():RadialEffectPool {
        if( !mInstance ) {
            mCanInitialize = true;
            mInstance = new RadialEffectPool();
            mCanInitialize = false;
        }
        return mInstance;
    }

    public static function dispose():void {
        if( mInstance ) {
            mInstance.dispose();
            mInstance = null;
        }
        mRadialEffectTexture = null;
    }

    override protected function getRadialEffectTexture():Texture {
        return mRadialEffectTexture;
    }

}

class LightRadialEffectPool extends BaseRadialEffectPool {

    public static var mRadialEffectTexture:Texture; // Provided by theme

    /* Singleton stuff */
    private static var mCanInitialize:Boolean;
    private static var mInstance:LightRadialEffectPool;

    public function LightRadialEffectPool() {
        super();

        if( !mCanInitialize ) throw new Error( "LightRadialEffectPool is a singleton, use getInstance()." );
    }

    public static function getInstance():LightRadialEffectPool {
        if( !mInstance ) {
            mCanInitialize = true;
            mInstance = new LightRadialEffectPool();
            mCanInitialize = false;
        }
        return mInstance;
    }

    public static function dispose():void {
        if( mInstance ) {
            mInstance.dispose();
            mInstance = null;
        }
        mRadialEffectTexture = null;
    }

    override protected function getRadialEffectTexture():Texture {
        return mRadialEffectTexture;
    }

}

class PrimaryRadialEffectPool extends BaseRadialEffectPool {

    public static var mRadialEffectTexture:Texture; // Provided by theme

    /* Singleton stuff */
    private static var mCanInitialize:Boolean;
    private static var mInstance:PrimaryRadialEffectPool;

    public function PrimaryRadialEffectPool() {
        super();

        if( !mCanInitialize ) throw new Error( "PrimaryRadialEffectPool is a singleton, use getInstance()." );
    }

    public static function getInstance():PrimaryRadialEffectPool {
        if( !mInstance ) {
            mCanInitialize = true;
            mInstance = new PrimaryRadialEffectPool();
            mCanInitialize = false;
        }
        return mInstance;
    }

    public static function dispose():void {
        if( mInstance ) {
            mInstance.dispose();
            mInstance = null;
        }
        mRadialEffectTexture = null;
    }

    override protected function getRadialEffectTexture():Texture {
        return mRadialEffectTexture;
    }

}

class AccentRadialEffectPool extends BaseRadialEffectPool {

    public static var mRadialEffectTexture:Texture; // Provided by theme

    /* Singleton stuff */
    private static var mCanInitialize:Boolean;
    private static var mInstance:AccentRadialEffectPool;

    public function AccentRadialEffectPool() {
        super();

        if( !mCanInitialize ) throw new Error( "AccentRadialEffectPool is a singleton, use getInstance()." );
    }

    public static function getInstance():AccentRadialEffectPool {
        if( !mInstance ) {
            mCanInitialize = true;
            mInstance = new AccentRadialEffectPool();
            mCanInitialize = false;
        }
        return mInstance;
    }

    public static function dispose():void {
        if( mInstance ) {
            mInstance.dispose();
            mInstance = null;
        }
        mRadialEffectTexture = null;
    }

    override protected function getRadialEffectTexture():Texture {
        return mRadialEffectTexture;
    }

}

class ToggleRadialEffectPool {

    public static var mRadialEffectOnTexture:Texture; // Provided by theme
    public static var mRadialEffectOffTexture:Texture; // Provided by theme

    private static var mOnTexturesPool:Vector.<Image>;
    private static var mOffTexturesPool:Vector.<Image>;

    public static function pop( isSelected:Boolean ):Image {
        if( !mOnTexturesPool ) init();

        var radialEffect:Image;
        if( isSelected && mOnTexturesPool.length > 0 ) {
            radialEffect = mOnTexturesPool.pop();
        } else if( !isSelected && mOffTexturesPool.length > 0 ) {
            radialEffect = mOffTexturesPool.pop();
        } else {
            radialEffect = new Image( isSelected ? mRadialEffectOnTexture : mRadialEffectOffTexture );
        }
        radialEffect.alignPivot();
        radialEffect.touchable = false;
        radialEffect.alpha = 0;
        return radialEffect;
    }

    public static function push( object:Image ):void {
        if( !mOnTexturesPool ) init();

        const targetPool:Vector.<Image> = (object.texture == mRadialEffectOnTexture) ? mOnTexturesPool : mOffTexturesPool;
        targetPool[targetPool.length] = object;
    }

    public static function dispose():void {
        mRadialEffectOnTexture = null;
        mRadialEffectOffTexture = null;
        if( mOnTexturesPool ) {
            /* 'On' textures pool */
            var length:uint = mOnTexturesPool.length;
            for( var i:uint = 0; i < length; i++ ) {
                mOnTexturesPool[i].dispose();
            }
            mOnTexturesPool = null;
            /* 'Off' textures pool */
            length = mOffTexturesPool.length;
            for( i = 0; i < length; i++ ) {
                mOffTexturesPool[i].dispose();
            }
            mOffTexturesPool = null;
        }
    }

    private static function init():void {
        mOnTexturesPool = new <Image>[];
        mOffTexturesPool = new <Image>[];
    }

}

class ShadowFilterPool {

	private static var mPool:Vector.<DropShadowFilter>;

	public static function pop():DropShadowFilter {
		if( !mPool ) init();

		var filter:DropShadowFilter;
		if( mPool.length > 0 ) {
			filter = mPool.pop();
		} else {
			filter = new DropShadowFilter( 0, Math.PI * 0.5, 0, 0.4, 0, 1 );
		}
		filter.blur = 0;
		filter.distance = 0;
		return filter;
	}

	public static function push( object:DropShadowFilter ):void {
		if( !mPool ) init();

		if( mPool.indexOf( object ) < 0 ) {
            mPool[mPool.length] = object;
        }
	}

	public static function dispose():void {
		if( mPool ) {
			const length:uint = mPool.length;
			for( var i:uint = 0; i < length; i++ ) {
				mPool[i].dispose();
			}
			mPool = null;
		}
	}

	private static function init():void {
		mPool = new <DropShadowFilter>[];
	}

}

class MaskPool {

    private static var mPool:Vector.<Quad>;

    public static function pop():Quad {
        if( !mPool ) init();

        var mask:Quad;
        if( mPool.length > 0 ) {
            mask = mPool.pop();
        } else {
            mask = new Quad( 10, 10, 0 );
        }
        mask.touchable = false;
        return mask;
    }

    public static function push( object:Quad ):void {
        if( !mPool ) init();

        if( mPool.indexOf( object ) < 0 ) {
            mPool[mPool.length] = object;
        }
    }

    public static function dispose():void {
        if( mPool ) {
            const length:uint = mPool.length;
            for( var i:uint = 0; i < length; i++ ) {
                mPool[i].dispose();
            }
            mPool = null;
        }
    }

    private static function init():void {
        mPool = new <Quad>[];
    }

}

/*
 Original work Copyright 2012-2016 Bowler Hat LLC. All rights reserved.
 Modified work Copyright 2016-2017 Marcel Piestansky

 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:

 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.

 2. Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

 The views and conclusions contained in the software and documentation are those
 of the authors and should not be interpreted as representing official policies,
 either expressed or implied, of the copyright holders.
 */
/**
 * A skin for Feathers components that displays a texture. Has the ability
 * to change its texture based on the current state of the Feathers
 * component that is being skinned. Uses two Image objects to achieve
 * a fading effect when the state skin changes.
 *
 * <listing version="3.0">
 * function setButtonSkin( button:Button ):void
 * {
 *     var skin:FadeImageSkin = new FadeImageSkin( upTexture );
 *     skin.setTextureForState( ButtonState.DOWN, downTexture );
 *     skin.setTextureForState( ButtonState.HOVER, hoverTexture );
 *     button.defaultSkin = skin;
 * }
 *
 * var button:Button = new Button();
 * button.label = "Click Me";
 * button.styleProvider = new AddOnFunctionStyleProvider( setButtonSkin, button.styleProvider );
 * this.addChild( button );</listing>
 */
class FadeImageSkin extends DisplayObjectContainer implements IMeasureDisplayObject, IStateObserver {

    protected const JUGGLER:Juggler = Starling.juggler;

    protected var mExplicitWidth:Number;
    protected var mExplicitHeight:Number;
    protected var mExplicitMinWidth:Number;
    protected var mExplicitMinHeight:Number;
    protected var mExplicitMaxWidth:Number = Number.POSITIVE_INFINITY;
    protected var mExplicitMaxHeight:Number = Number.POSITIVE_INFINITY;
    protected var mPreviousState:String;
    protected var mPreviousSkinTweenID:uint;
    protected var mActiveSkinTweenID:uint;
    protected var mColorTweenID:uint;
    protected var mToggleTransitionDC:uint;
    protected var mFadeInDuration:Number;
    protected var mFadeInTransition:String;
    protected var mFadeOutDuration:Number;
    protected var mFadeOutTransition:String;
    protected var mTweenColorChange:Boolean;
    protected var mColorTweenDuration:Number;
    protected var mColorTweenTransition:String;

    protected var mStateContext:IStateContext;
    protected var mStateToTexture:Object;
    protected var mStateToColor:Object = {};
    protected var mScale9Grid:Rectangle;

    protected var mDefaultTexture:Texture;
    protected var mDisabledTexture:Texture;
    protected var mSelectedTexture:Texture;

    protected var mDefaultColor:uint;
    protected var mDisabledColor:uint;
    protected var mSelectedColor:uint;

    protected var mPrevSkin:Image;
    protected var mActiveSkin:Image;

    public function FadeImageSkin( texture:Texture ) {
        super();

        mDefaultTexture = texture;
        mFadeInDuration = mFadeOutDuration = mColorTweenDuration = 0.5;
        mFadeInTransition = mColorTweenTransition = Transitions.EASE_OUT;
        mFadeOutTransition = Transitions.EASE_IN;
        mDefaultColor = uint.MAX_VALUE;
        mDisabledColor = uint.MAX_VALUE;
        mSelectedColor = uint.MAX_VALUE;

        mStateToTexture = {};
    }

    /**
     *
     *
     * Public API
     *
     *
     */

    /**
     * Gets the texture to be used by the skin when the context's
     * <code>currentState</code> property matches the specified state value.
     *
     * <p>If a texture is not defined for a specific state, returns
     * <code>null</code>.</p>
     *
     * @see #setTextureForState()
     */
    public function getTextureForState( state:String ):Texture {
        return mStateToTexture[state] as Texture;
    }

    /**
     * Sets the texture to be used by the skin when the context's
     * <code>currentState</code> property matches the specified state value.
     *
     * <p>If a texture is not defined for a specific state, the value of the
     * <code>defaultTexture</code> property will be used instead.</p>
     *
     * @see #defaultTexture
     */
    public function setTextureForState( state:String, texture:Texture ):void {
        if( texture !== null ) {
            mStateToTexture[state] = texture;
        } else {
            delete mStateToTexture[state];
        }
        updateTextureFromContext();
    }

    /**
     * Gets the color to be used by the skin when the context's
     * <code>currentState</code> property matches the specified state value.
     *
     * <p>If a color is not defined for a specific state, returns
     * <code>uint.MAX_VALUE</code>.</p>
     *
     * @see #setColorForState()
     */
    public function getColorForState( state:String ):uint {
        if( state in mStateToColor ) {
            return mStateToColor[state] as uint;
        }
        return uint.MAX_VALUE;
    }

    /**
     * Sets the color to be used by the skin when the context's
     * <code>currentState</code> property matches the specified state value.
     *
     * <p>If a color is not defined for a specific state, the value of the
     * <code>defaultTexture</code> property will be used instead.</p>
     *
     * <p>To clear a state's color, pass in <code>uint.MAX_VALUE</code>.</p>
     *
     * @see #defaultColor
     * @see #getColorForState()
     */
    public function setColorForState( state:String, color:uint ):void {
        if( color !== uint.MAX_VALUE ) {
            mStateToColor[state] = color;
        } else {
            delete mStateToColor[state];
        }
        updateColorFromContext();
    }

    /**
     *
     *
     * Private API
     *
     *
     */

    private function getImage( texture:Texture, image:Image ):Image {
        if( image ) {
            image.texture = texture;
        } else {
            image = new Image( texture );
        }
        if( mScale9Grid !== null && (image.scale9Grid === null || !image.scale9Grid.equals( mScale9Grid )) ) {
            image.scale9Grid = mScale9Grid;
        }
        return image;
    }

    private function resizeImage( image:Image ):void {
        if( mExplicitWidth === mExplicitWidth && //!isNaN
                image.width !== mExplicitWidth ) {
            image.width = mExplicitWidth;
        }
        if( mExplicitHeight === mExplicitHeight && //!isNaN
                image.height !== mExplicitHeight ) {
            image.height = mExplicitHeight;
        }
    }

    private function delayedTransition():void {
        mToggleTransitionDC = 0;
        updateTextureFromContext();
        updateColorFromContext();
    }

    /**
     *
     *
     * Protected API
     *
     *
     */

    protected function updateTextureFromContext():void {
        if( mStateContext === null ) {
            if( mDefaultTexture !== null && mActiveSkin === null ) {
                mActiveSkin = new Image( mDefaultTexture );
                addChildAt( mActiveSkin, 0 );
            }
            return;
        }
        var currentState:String = mStateContext.currentState;
        if( mPreviousState !== currentState ) {
            var texture:Texture = mStateToTexture[currentState] as Texture;
            if( texture === null &&
                    mDisabledTexture !== null &&
                    mStateContext is IFeathersControl && !IFeathersControl( mStateContext ).isEnabled ) {
                texture = mDisabledTexture;
            }
            var isToggle:Boolean = mStateContext is IToggle;
            if( texture === null &&
                    mSelectedTexture !== null &&
                    isToggle &&
                    IToggle( mStateContext ).isSelected ) {
                texture = mSelectedTexture;
            }
            if( texture === null ) {
                texture = mDefaultTexture;
            }

            /* By default, state change from DOWN to UP_AND_SELECTED has this flow:
             *  DOWN -> UP -> UP_AND_SELECTED
             * This delayed call prevents immediate change to UP state when it is not needed.
             * Is there a better way to prevent it? Please, show me. */
            if( mToggleTransitionDC > 0 ) {
                JUGGLER.removeByID( mToggleTransitionDC );
                mToggleTransitionDC = 0;
            }
            if( isToggle &&
                    ((mPreviousState == ButtonState.DOWN && currentState == ButtonState.UP) ||
                    (mPreviousState == ButtonState.DOWN_AND_SELECTED && currentState == ButtonState.UP_AND_SELECTED)) ) {
                mPreviousState = null;
                mToggleTransitionDC = JUGGLER.delayCall( delayedTransition, 0.05 );
                return;
            }

            mPreviousState = currentState;
            var prevSkin:Image = null;
            var activeSkin:Image = null;
            if( mActiveSkin !== null ) {
                /* Active image already has the texture we want to transition to */
                if( mActiveSkin.texture == texture ) return;
                /* The current skin becomes previous so that it can be faded out */
                if( mActiveSkin.texture !== null ) {
                    mPrevSkin = getImage( mActiveSkin.texture, mPrevSkin );
                    mPrevSkin.color = mActiveSkin.color;
                    mPrevSkin.width = mActiveSkin.width;
                    mPrevSkin.height = mActiveSkin.height;
                    addChildAt( mPrevSkin, 0 );
                    prevSkin = mPrevSkin;
                }
            } else if( mPrevSkin !== null ) {
                mPrevSkin.removeFromParent();
            }
            /* If there is a new skin then assign it to Image */
            if( texture !== null ) {
                mActiveSkin = getImage( texture, mActiveSkin );
                mActiveSkin.color = 0xFFFFFF;
                resizeImage( mActiveSkin );
                addChild( mActiveSkin );
                activeSkin = mActiveSkin;
            } else if( mActiveSkin !== null ) {
                mActiveSkin.removeFromParent();
                mActiveSkin.texture = null;
            }
            animate( activeSkin, prevSkin );
        }
    }

    protected function updateColorFromContext():void {
        if( mStateContext === null ) {
            if( mDefaultColor !== uint.MAX_VALUE && mActiveSkin !== null && mActiveSkin.texture !== null ) {
                mActiveSkin.color = mDefaultColor;
            }
            return;
        }
        var color:uint = uint.MAX_VALUE;
        var currentState:String = mStateContext.currentState;
        if( currentState in mStateToColor ) {
            color = mStateToColor[currentState] as uint;
        }
        if( color === uint.MAX_VALUE &&
                mDisabledColor !== uint.MAX_VALUE &&
                mStateContext is IFeathersControl && !IFeathersControl( mStateContext ).isEnabled ) {
            color = mDisabledColor;
        }
        if( color === uint.MAX_VALUE &&
                mSelectedColor !== uint.MAX_VALUE &&
                mStateContext is IToggle &&
                IToggle( mStateContext ).isSelected ) {
            color = mSelectedColor;
        }
        if( color === uint.MAX_VALUE ) {
            color = mDefaultColor;
        }
        if( color !== uint.MAX_VALUE && mActiveSkin !== null && mActiveSkin.texture !== null ) {
            if( mTweenColorChange ) {
                if( mColorTweenID > 0 ) {
                    JUGGLER.removeByID( mColorTweenID );
                }
                mColorTweenID = JUGGLER.tween( mActiveSkin, mColorTweenDuration, {
                    color: color,
                    transition: mColorTweenTransition,
                    onComplete: function():void {
                        mColorTweenID = 0;
                    }
                } );
            } else {
                mActiveSkin.color = color;
            }
        }
    }

    protected function animate( activeSkin:Image, prevSkin:Image ):void {
        if( prevSkin !== null ) {
            prevSkin.alpha = 1;
            if( mPreviousSkinTweenID > 0 ) {
                JUGGLER.removeByID( mPreviousSkinTweenID );
            }
            mPreviousSkinTweenID = JUGGLER.tween( prevSkin, mFadeOutDuration, {
                alpha: 0,
                transition: mFadeOutTransition,
                onComplete: function ():void {
                    mPreviousSkinTweenID = 0;
                }
            } );
        }
        if( activeSkin !== null ) {
            activeSkin.alpha = 0;
            if( mActiveSkinTweenID > 0 ) {
                JUGGLER.removeByID( mActiveSkinTweenID );
            }
            mActiveSkinTweenID = JUGGLER.tween( activeSkin, mFadeInDuration, {
                alpha: 1,
                transition: mFadeInTransition,
                onComplete: function ():void {
                    mActiveSkinTweenID = 0;
                }
            } );
        }
    }

    protected function onStateContextChanged():void {
        updateTextureFromContext();
        updateColorFromContext();
    }

    /**
     *
     *
     * Getters / Setters
     *
     *
     */

    /**
     * When the skin observes a state context, the skin may change its
     * <code>Texture</code> based on the current state of that context.
     * Typically, a relevant component will automatically assign itself as
     * the state context of its skin, so this property is considered to be
     * for internal use only.
     *
     * @default null
     *
     * @see #setTextureForState()
     */
    public function get stateContext():IStateContext {
        return mStateContext;
    }

    public function set stateContext( value:IStateContext ):void {
        if( mStateContext === value ) {
            return;
        }
        if( mStateContext ) {
            mStateContext.removeEventListener( FeathersEventType.STATE_CHANGE, onStateContextChanged );
        }
        mStateContext = value;
        if( mStateContext ) {
            mStateContext.addEventListener( FeathersEventType.STATE_CHANGE, onStateContextChanged );
        }
        updateTextureFromContext();
        updateColorFromContext();
    }

    /**
     * The value passed to the <code>width</code> property setter. If the
     * <code>width</code> property has not be set, returns <code>NaN</code>.
     *
     * @see #width
     */
    public function get explicitWidth():Number {
        return mExplicitWidth;
    }

    override public function set width( value:Number ):void {
        if( mExplicitWidth === value ) {
            return;
        }
        if( value !== value && mExplicitWidth !== mExplicitWidth ) {
            return;
        }
        mExplicitWidth = value;
        if( mActiveSkin !== null ) {
            if( value === value ) { //!isNaN
                mActiveSkin.width = value;
            } else { // return to the original width of the texture
                mActiveSkin.readjustSize();
            }
        }
        dispatchEventWith( Event.RESIZE );
    }

    override public function get width():Number {
        return mActiveSkin ? mActiveSkin.width : NaN;
    }

    /**
     * The value passed to the <code>height</code> property setter. If the
     * <code>height</code> property has not be set, returns
     * <code>NaN</code>.
     *
     * @see #height
     */
    public function get explicitHeight():Number {
        return mExplicitHeight;
    }

    override public function set height( value:Number ):void {
        if( mExplicitHeight === value ) {
            return;
        }
        if( value !== value && mExplicitHeight !== mExplicitHeight ) {
            return;
        }
        mExplicitHeight = value;
        if( mActiveSkin !== null ) {
            if( value === value ) { //!isNaN
                mActiveSkin.height = value;
            } else { //return to the original height of the texture
                mActiveSkin.readjustSize();
            }
        }
        dispatchEventWith( Event.RESIZE );
    }

    override public function get height():Number {
        return mActiveSkin ? mActiveSkin.height : NaN;
    }

    /**
     * The value passed to the <code>minWidth</code> property setter. If the
     * <code>minWidth</code> property has not be set, returns
     * <code>NaN</code>.
     *
     * @see #minWidth
     */
    public function get explicitMinWidth():Number {
        return mExplicitMinWidth;
    }

    public function get minWidth():Number {
        if( mExplicitMinWidth === mExplicitMinWidth ) { //!isNaN
            return mExplicitMinWidth;
        }
        return 0;
    }

    public function set minWidth( value:Number ):void {
        if( mExplicitMinWidth === value ) {
            return;
        }
        if( value !== value && mExplicitMinWidth !== mExplicitMinWidth ) {
            return;
        }
        mExplicitMinWidth = value;
        dispatchEventWith( Event.RESIZE );
    }

    /**
     * The value passed to the <code>maxWidth</code> property setter. If the
     * <code>maxWidth</code> property has not be set, returns
     * <code>NaN</code>.
     *
     * @see #maxWidth
     */
    public function get explicitMaxWidth():Number {
        return mExplicitMaxWidth;
    }

    /**
     * The maximum width of the component.
     */
    public function get maxWidth():Number {
        return mExplicitMaxWidth;
    }

    /**
     * @private
     */
    public function set maxWidth(value:Number):void {
        if( mExplicitMaxWidth === value ) {
            return;
        }
        if( value !== value && mExplicitMaxWidth !== mExplicitMaxWidth ) {
            return;
        }
        mExplicitMaxWidth = value;
        dispatchEventWith( Event.RESIZE );
    }

    /**
     * The value passed to the <code>minHeight</code> property setter. If
     * the <code>minHeight</code> property has not be set, returns
     * <code>NaN</code>.
     *
     * @see #minHeight
     */
    public function get explicitMinHeight():Number {
        return mExplicitMinHeight;
    }

    public function get minHeight():Number {
        if( mExplicitMinHeight === mExplicitMinHeight ) { //!isNaN
            return mExplicitMinHeight;
        }
        return 0;
    }

    public function set minHeight( value:Number ):void {
        if( mExplicitMinHeight === value ) {
            return;
        }
        if( value !== value && mExplicitMinHeight !== mExplicitMinHeight ) {
            return;
        }
        mExplicitMinHeight = value;
        dispatchEventWith( Event.RESIZE );
    }

    /**
     * The value passed to the <code>maxHeight</code> property setter. If
     * the <code>maxHeight</code> property has not be set, returns
     * <code>NaN</code>.
     *
     * @see #maxHeight
     */
    public function get explicitMaxHeight():Number {
        return mExplicitMaxHeight;
    }

    /**
     * The maximum height of the component.
     */
    public function get maxHeight():Number {
        return mExplicitMaxHeight;
    }

    /**
     * @private
     */
    public function set maxHeight(value:Number):void {
        if( mExplicitMaxHeight === value ) {
            return;
        }
        if( value !== value && mExplicitMaxHeight !== mExplicitMaxHeight ) {
            return;
        }
        mExplicitMaxHeight = value;
        dispatchEventWith( Event.RESIZE );
    }

    /**
     * The default texture that the skin will display. If the component
     * being skinned supports states, the texture for a specific state may
     * be specified using the <code>setTextureForState()</code> method. If
     * no texture has been specified for the current state, the default
     * texture will be used.
     *
     * <p>In the following example, the default texture is specified in the
     * constructor:</p>
     *
     * <listing version="3.0">
     * var skin:FadeImageSkin = new FadeImageSkin( texture );</listing>
     *
     * <p>In the following example, the default texture is specified by
     * setting the property:</p>
     *
     * <listing version="3.0">
     * var skin:FadeImageSkin = new FadeImageSkin();
     * skin.defaultTexture = texture;</listing>
     *
     * @default null
     *
     * @see #disabledTexture
     * @see #selectedTexture
     * @see #setTextureForState()
     * @see http://doc.starling-framework.org/current/starling/textures/Texture.html starling.textures.Texture
     */
    public function get defaultTexture():Texture {
        return mDefaultTexture;
    }

    /**
     * @private
     */
    public function set defaultTexture( value:Texture ):void {
        if( mDefaultTexture === value ) {
            return;
        }
        mDefaultTexture = value;
        updateTextureFromContext();
    }

    /**
     * The texture to display when the <code>stateContext</code> is
     * an <code>IFeathersControl</code> and its <code>isEnabled</code>
     * property is <code>false</code>. If a texture has been specified for
     * the context's current state with <code>setTextureForState()</code>,
     * it will take precedence over the <code>disabledTexture</code>.
     *
     * <p>In the following example, the disabled texture is changed:</p>
     *
     * <listing version="3.0">
     * var skin:FadeImageSkin = new FadeImageSkin( upTexture );
     * skin.disabledTexture = disabledTexture;
     * button.skin = skin;
     * button.isEnabled = false;</listing>
     *
     * @default null
     *
     * @see #defaultTexture
     * @see #selectedTexture
     * @see #setTextureForState()
     * @see http://doc.starling-framework.org/current/starling/textures/Texture.html starling.textures.Texture
     */
    public function get disabledTexture():Texture {
        return mDisabledTexture;
    }

    /**
     * @private
     */
    public function set disabledTexture( value:Texture ):void {
        mDisabledTexture = value;
    }

    /**
     * The texture to display when the <code>stateContext</code> is
     * an <code>IToggle</code> instance and its <code>isSelected</code>
     * property is <code>true</code>. If a texture has been specified for
     * the context's current state with <code>setTextureForState()</code>,
     * it will take precedence over the <code>selectedTexture</code>.
     *
     * <p>In the following example, the selected texture is changed:</p>
     *
     * <listing version="3.0">
     * var skin:FadeImageSkin = new FadeImageSkin( upTexture );
     * skin.selectedTexture = selectedTexture;
     * toggleButton.skin = skin;
     * toggleButton.isSelected = true;</listing>
     *
     * @default null
     *
     * @see #defaultTexture
     * @see #disabledTexture
     * @see #setTextureForState()
     * @see http://doc.starling-framework.org/current/starling/textures/Texture.html starling.textures.Texture
     */
    public function get selectedTexture():Texture {
        return mSelectedTexture;
    }

    /**
     * @private
     */
    public function set selectedTexture( value:Texture ):void {
        mSelectedTexture = value;
    }

    /**
     * Scaling grid used for the internal images.
     *
     * @see http://doc.starling-framework.org/current/starling/display/Image.html#scale9Grid starling.display.Image
     */
    public function get scale9Grid():Rectangle {
        return mScale9Grid;
    }

    /**
     * @private
     */
    public function set scale9Grid( value:Rectangle ):void {
        mScale9Grid = value;

        if( mActiveSkin !== null ) {
            mActiveSkin.scale9Grid = value;
        }
    }

    /**
     * The duration of the fade in Tween, in seconds.
     *
     * @default 0.5
     */
    public function get fadeInDuration():Number {
        return mFadeInDuration;
    }

    /**
     * @private
     */
    public function set fadeInDuration( value:Number ):void {
        mFadeInDuration = value;
    }

    /**
     * The duration of the fade out Tween, in seconds.
     *
     * @default 0.5
     */
    public function get fadeOutDuration():Number {
        return mFadeOutDuration;
    }

    /**
     * @private
     */
    public function set fadeOutDuration( value:Number ):void {
        mFadeOutDuration = value;
    }

    /**
     * Name of the transition used to fade in current skin.
     *
     * @default starling.animation.Transitions.EASE_OUT
     *
     * @see http://doc.starling-framework.org/current/starling/animation/Transitions.html starling.animation.Transitions
     */
    public function get fadeInTransition():String {
        return mFadeInTransition;
    }

    /**
     * @private
     */
    public function set fadeInTransition( value:String ):void {
        mFadeInTransition = value;
    }

    /**
     * Name of the transition used to fade out previous skin.
     *
     * @default starling.animation.Transitions.EASE_IN
     *
     * @see http://doc.starling-framework.org/current/starling/animation/Transitions.html starling.animation.Transitions
     */
    public function get fadeOutTransition():String {
        return mFadeOutTransition;
    }

    /**
     * @private
     */
    public function set fadeOutTransition( value:String ):void {
        mFadeOutTransition = value;
    }

    /**
     * Determines if a color change is animated when component's state changes.
     * Useful when having a single skin texture for all states but various colors.
     *
     * @default false
     */
    public function get tweenColorChange():Boolean {
        return mTweenColorChange;
    }

    /**
     * @private
     */
    public function set tweenColorChange( value:Boolean ):void {
        mTweenColorChange = value;
    }

    /**
     * Duration of the tween that changes the skin color.
     *
     * @default 0.5
     */
    public function get colorTweenDuration():Number {
        return mColorTweenDuration;
    }

    /**
     * @private
     */
    public function set colorTweenDuration( value:Number ):void {
        mColorTweenDuration = value;
    }

    /**
     * Transition of the tween that changes the skin color.
     *
     * @default starling.animation.Transitions.EASE_OUT
     *
     * @see http://doc.starling-framework.org/current/starling/animation/Transitions.html starling.animation.Transitions
     */
    public function get colorTweenTransition():String {
        return mColorTweenTransition;
    }

    /**
     * @private
     */
    public function set colorTweenTransition( value:String ):void {
        mColorTweenTransition = value;
    }

    /**
     * The default color to use to tint the skin. If the component
     * being skinned supports states, the color for a specific state may
     * be specified using the <code>setColorForState()</code> method. If
     * no color has been specified for the current state, the default
     * color will be used.
     *
     * <p>A value of <code>uint.MAX_VALUE</code> means that the
     * <code>color</code> property will not be changed when the context's
     * state changes.</p>
     *
     * <p>In the following example, the default color is specified:</p>
     *
     * <listing version="3.0">
     * var skin:FadeImageSkin = new FadeImageSkin();
     * skin.defaultColor = 0x9f0000;</listing>
     *
     * @default uint.MAX_VALUE
     *
     * @see #disabledColor
     * @see #selectedColor
     * @see #setColorForState()
     */
    public function get defaultColor():uint {
        return mDefaultColor;
    }

    /**
     * @private
     */
    public function set defaultColor( value:uint ):void {
        if( mDefaultColor === value ) {
            return;
        }
        mDefaultColor = value;
        updateColorFromContext();
    }

    /**
     * The color to tint the skin when the <code>stateContext</code> is
     * an <code>IFeathersControl</code> and its <code>isEnabled</code>
     * property is <code>false</code>. If a color has been specified for
     * the context's current state with <code>setColorForState()</code>,
     * it will take precedence over the <code>disabledColor</code>.
     *
     * <p>A value of <code>uint.MAX_VALUE</code> means that the
     * <code>disabledColor</code> property cannot affect the tint when the
     * context's state changes.</p>
     *
     * <p>In the following example, the disabled color is changed:</p>
     *
     * <listing version="3.0">
     * var skin:FadeImageSkin = new FadeImageSkin();
     * skin.defaultColor = 0xffffff;
     * skin.disabledColor = 0x999999;
     * button.skin = skin;
     * button.isEnabled = false;</listing>
     *
     * @default uint.MAX_VALUE
     *
     * @see #defaultColor
     * @see #selectedColor
     * @see #setColorForState()
     */
    public function get disabledColor():uint {
        return mDisabledColor;
    }

    /**
     * @private
     */
    public function set disabledColor( value:uint ):void {
        if( mDisabledColor === value ) {
            return;
        }
        mDisabledColor = value;
        updateColorFromContext();
    }

    /**
     * The color to tint the skin when the <code>stateContext</code> is
     * an <code>IToggle</code> instance and its <code>isSelected</code>
     * property is <code>true</code>. If a color has been specified for
     * the context's current state with <code>setColorForState()</code>,
     * it will take precedence over the <code>selectedColor</code>.
     *
     * <p>In the following example, the selected color is changed:</p>
     *
     * <listing version="3.0">
     * var skin:FadeImageSkin = new FadeImageSkin();
     * skin.defaultColor = 0xffffff;
     * skin.selectedColor = 0xffcc00;
     * toggleButton.skin = skin;
     * toggleButton.isSelected = true;</listing>
     *
     * @default uint.MAX_VALUE
     *
     * @see #defaultColor
     * @see #disabledColor
     * @see #setColorForState()
     */
    public function get selectedColor():uint {
        return mSelectedColor;
    }

    /**
     * @private
     */
    public function set selectedColor( value:uint ):void {
        if( mSelectedColor === value ) {
            return;
        }
        mSelectedColor = value;
        updateColorFromContext();
    }

}