clenza
├── README.md
├── analysis_options.yaml
├── android
├── assets
│   ├── animations
│   │   ├── Building.json
│   │   ├── Error 404.json
│   │   ├── Sandy Loading Animation.json
│   │   ├── admin_approve_animation.json
│   │   ├── admin_approving_processing.json
│   │   ├── call booking.json
│   │   ├── call.json
│   │   ├── checking_all.json
│   │   ├── leadership.json
│   │   ├── login_with_OPT.json
│   │   ├── mainenanse.json
│   │   ├── oops_error.json
│   │   ├── registeration_done.json
│   │   ├── sending_loading.json
│   │   ├── sett_location_map.json
│   │   ├── sport and arts
│   │   │   ├── Archery Man Animation.json
│   │   │   ├── Basketball Player Animation.json
│   │   │   ├── Olympics Animation.json
│   │   │   ├── arts.json
│   │   │   ├── boxer lottie Animation.json
│   │   │   ├── criket.json
│   │   │   ├── kick on the ball Animation.json
│   │   │   └── rope exercise Animation.json
│   │   ├── tried.json
│   │   ├── user restration Done.json
│   │   └── verification_done.json
│   ├── images
│   │   └── splashscreen
│   │       ├── logo_c.png
│   │       ├── logo_globe.png
│   │       ├── text_lubsph.png
│   │       └── text_re.png
│   └── logo
│       ├── app_icon_backgroundremoved.png
│       └── app_logo.png
├── build
├── clenza.iml
├── ios
├── lib
│   ├── core
│   │   ├── constants
│   │   │   ├── app_strings.dart
│   │   │   ├── route_constants.dart
│   │   │   └── supabase_constants.dart
│   │   ├── errors
│   │   │   ├── exceptions.dart
│   │   │   └── failures.dart
│   │   ├── theme
│   │   │   ├── app_colors.dart
│   │   │   ├── app_text_styles.dart
│   │   │   └── app_theme.dart
│   │   ├── utils
│   │   │   ├── id_generator.dart
│   │   │   ├── permission_guard.dart
│   │   │   └── router.dart
│   │   └── widgets
│   │       ├── cs_avatar.dart
│   │       ├── cs_badge.dart
│   │       ├── cs_button.dart
│   │       ├── cs_card.dart
│   │       ├── cs_empty_state.dart
│   │       ├── cs_loading.dart
│   │       └── cs_text_field.dart
│   ├── features
│   │   ├── auth
│   │   │   ├── data
│   │   │   │   ├── datasources
│   │   │   │   │   └── auth_remote_datasource.dart
│   │   │   │   ├── models
│   │   │   │   │   └── user_model.dart
│   │   │   │   └── repositories
│   │   │   │       └── auth_repository_impl.dart
│   │   │   ├── domain
│   │   │   │   ├── entities
│   │   │   │   │   └── club_user.dart
│   │   │   │   ├── repositories
│   │   │   │   │   └── auth_repository.dart
│   │   │   │   └── usecases
│   │   │   │       └── auth_usecases.dart
│   │   │   └── presentation
│   │   │       ├── providers
│   │   │       │   └── auth_provider.dart
│   │   │       └── screens
│   │   │           ├── login_screen.dart
│   │   │           ├── register_club_screen.dart
│   │   │           ├── set_password_screen.dart
│   │   │           └── splash_screen.dart
│   │   ├── dashboard
│   │   │   └── presentation
│   │   │       └── screens
│   │   │           ├── dashboard_screen.dart
│   │   │           ├── dashboard_shell.dart
│   │   │           └── more_screen.dart
│   │   ├── documents
│   │   │   └── presentation
│   │   │       └── screens
│   │   ├── elections
│   │   │   └── presentation
│   │   │       └── screens
│   │   ├── events
│   │   │   ├── data
│   │   │   │   ├── datasources
│   │   │   │   │   └── event_remote_datasource.dart
│   │   │   │   ├── models
│   │   │   │   │   └── event_model.dart
│   │   │   │   └── repositories
│   │   │   │       └── event_repository_impl.dart
│   │   │   ├── domain
│   │   │   │   ├── entities
│   │   │   │   │   └── event_entity.dart
│   │   │   │   ├── repositories
│   │   │   │   │   └── event_repository.dart
│   │   │   │   └── usecases
│   │   │   │       └── event_usecases.dart
│   │   │   └── presentation
│   │   │       ├── providers
│   │   │       │   └── event_provider.dart
│   │   │       ├── screens
│   │   │       │   ├── create_event_screen.dart
│   │   │       │   └── events_list_screen.dart
│   │   │       └── widgets
│   │   ├── finance
│   │   │   ├── data
│   │   │   │   ├── datasources
│   │   │   │   │   └── finance_remote_datasource.dart
│   │   │   │   ├── models
│   │   │   │   │   └── transaction_model.dart
│   │   │   │   └── repositories
│   │   │   │       └── finance_repository_impl.dart
│   │   │   ├── domain
│   │   │   │   ├── entities
│   │   │   │   │   └── transaction_entity.dart
│   │   │   │   ├── repositories
│   │   │   │   │   └── finance_repository.dart
│   │   │   │   └── usecases
│   │   │   │       └── finance_usecases.dart
│   │   │   └── presentation
│   │   │       ├── providers
│   │   │       │   └── finance_provider.dart
│   │   │       ├── screens
│   │   │       │   ├── add_transaction_screen.dart
│   │   │       │   └── finance_screen.dart
│   │   │       └── widgets
│   │   ├── members
│   │   │   ├── data
│   │   │   │   ├── datasources
│   │   │   │   │   └── member_remote_datasource.dart
│   │   │   │   ├── models
│   │   │   │   └── repositories
│   │   │   │       └── member_repository_impl.dart
│   │   │   ├── domain
│   │   │   │   ├── repositories
│   │   │   │   │   └── member_repository.dart
│   │   │   │   └── usecases
│   │   │   │       └── member_usecases.dart
│   │   │   └── presentation
│   │   │       ├── providers
│   │   │       │   └── member_provider.dart
│   │   │       ├── screens
│   │   │       │   ├── add_member_screen.dart
│   │   │       │   └── members_list_screen.dart
│   │   │       └── widgets
│   │   └── notifications
│   │       └── presentation
│   │           └── screens
│   └── main.dart
├── linux
├── macos
├── pubspec.lock
├── pubspec.yaml
├── test
│   └── widget_test.dart
├── web
└── windows
clenza_admin_web
├── README.md
├── analysis_options.yaml
├── android
├── assets
│   ├── animations
│   │   ├── Error 404.json
│   │   ├── Sandy Loading Animation.json
│   │   ├── admin_approve_animation.json
│   │   ├── call booking.json
│   │   ├── call.json
│   │   ├── checking_all.json
│   │   ├── login_with_OPT.json
│   │   ├── mainenanse.json
│   │   ├── oops_error.json
│   │   ├── registeration_done.json
│   │   ├── sending_loading.json
│   │   ├── sett_location_map.json
│   │   ├── sport and arts
│   │   │   ├── Archery Man Animation.json
│   │   │   ├── Basketball Player Animation.json
│   │   │   ├── Olympics Animation.json
│   │   │   ├── arts.json
│   │   │   ├── boxer lottie Animation.json
│   │   │   ├── criket.json
│   │   │   ├── kick on the ball Animation.json
│   │   │   └── rope exercise Animation.json
│   │   ├── tried.json
│   │   ├── user restration Done.json
│   │   └── verification_done.json
│   ├── images
│   │   └── splashscreen
│   │       ├── logo_c.png
│   │       ├── logo_globe.png
│   │       ├── text_lubsph.png
│   │       └── text_re.png
│   └── logo
│       ├── app_icon_backgroundremoved.png
│       └── app_logo.png
├── build
├── clenza_admin_web.iml
├── ios
├── lib
│   ├── core
│   │   ├── components
│   │   │   ├── admin_layout.dart
│   │   │   ├── stat_card.dart
│   │   │   └── status_badge.dart
│   │   ├── constants
│   │   │   ├── app_strings.dart
│   │   │   ├── route_constants.dart
│   │   │   └── supabase_constants.dart
│   │   ├── errors
│   │   │   ├── exceptions.dart
│   │   │   └── failures.dart
│   │   ├── theme
│   │   │   ├── app_colors.dart
│   │   │   ├── app_text_styles.dart
│   │   │   └── app_theme.dart
│   │   ├── utils
│   │   │   ├── id_generator.dart
│   │   │   └── permission_guard.dart
│   │   └── widgets
│   │       ├── admin_sidebar.dart
│   │       ├── clay_card.dart
│   │       ├── cs_avatar.dart
│   │       ├── cs_badge.dart
│   │       ├── cs_button.dart
│   │       ├── cs_card.dart
│   │       ├── cs_empty_state.dart
│   │       ├── cs_loading.dart
│   │       └── cs_text_field.dart
│   ├── features
│   │   ├── approvals
│   │   │   ├── data
│   │   │   │   └── repositories
│   │   │   │       └── club_repository.dart
│   │   │   └── presentation
│   │   │       └── screens
│   │   │           ├── approvals_screen.dart
│   │   │           └── approvals_tab.dart
│   │   ├── auth
│   │   │   ├── data
│   │   │   │   └── repositories
│   │   │   │       └── auth_repository.dart
│   │   │   └── presentation
│   │   │       └── screens
│   │   │           ├── login_screen.dart
│   │   │           ├── splash_screen.dart
│   │   │           └── users_list_tab.dart
│   │   ├── broadcast
│   │   │   └── presentation
│   │   │       └── screens
│   │   │           ├── broadcast_screen.dart
│   │   │           └── broadcast_tab.dart
│   │   ├── clubs
│   │   │   ├── data
│   │   │   │   └── repositories
│   │   │   └── presentation
│   │   │       └── screens
│   │   │           ├── clubs_list_tab.dart
│   │   │           └── clubs_screen.dart
│   │   ├── dashboard
│   │   │   ├── data
│   │   │   │   ├── providers
│   │   │   │   │   └── admin_provider.dart
│   │   │   │   └── repositories
│   │   │   │       └── analytics_repository.dart
│   │   │   └── presentation
│   │   │       └── screens
│   │   │           ├── admin_home_screen.dart
│   │   │           ├── dashboard_screen.dart
│   │   │           └── overview_tab.dart
│   │   └── settings
│   │       └── presentation
│   │           └── screens
│   │               └── settings_screen.dart
│   └── main.dart
├── linux
├── macos
├── pubspec.lock
├── pubspec.yaml
├── test
├── web
└── windows
clenza_tv_app
├── README.md
├── analysis_options.yaml
├── android
├── assets
│   ├── animations
│   │   ├── Error 404.json
│   │   ├── Sandy Loading Animation.json
│   │   ├── admin_approve_animation.json
│   │   ├── call booking.json
│   │   ├── call.json
│   │   ├── checking_all.json
│   │   ├── login_with_OPT.json
│   │   ├── mainenanse.json
│   │   ├── oops_error.json
│   │   ├── registeration_done.json
│   │   ├── sending_loading.json
│   │   ├── sett_location_map.json
│   │   ├── sport and arts
│   │   │   ├── Archery Man Animation.json
│   │   │   ├── Basketball Player Animation.json
│   │   │   ├── Olympics Animation.json
│   │   │   ├── arts.json
│   │   │   ├── boxer lottie Animation.json
│   │   │   ├── criket.json
│   │   │   ├── kick on the ball Animation.json
│   │   │   └── rope exercise Animation.json
│   │   ├── tried.json
│   │   ├── user restration Done.json
│   │   └── verification_done.json
│   ├── images
│   │   └── splashscreen
│   │       ├── logo_c.png
│   │       ├── logo_globe.png
│   │       ├── text_lubsph.png
│   │       └── text_re.png
│   └── logo
│       ├── app_icon_backgroundremoved.png
│       └── app_logo.png
├── build
├── clenza_tv_app.iml
├── ios
├── lib
│   ├── core
│   │   ├── constants
│   │   │   ├── app_strings.dart
│   │   │   ├── route_constants.dart
│   │   │   └── supabase_constants.dart
│   │   ├── errors
│   │   │   ├── exceptions.dart
│   │   │   └── failures.dart
│   │   ├── theme
│   │   │   ├── app_colors.dart
│   │   │   ├── app_text_styles.dart
│   │   │   └── app_theme.dart
│   │   ├── utils
│   │   │   ├── id_generator.dart
│   │   │   └── permission_guard.dart
│   │   └── widgets
│   │       ├── cs_avatar.dart
│   │       ├── cs_badge.dart
│   │       ├── cs_button.dart
│   │       ├── cs_card.dart
│   │       ├── cs_empty_state.dart
│   │       ├── cs_loading.dart
│   │       └── cs_text_field.dart
│   └── main.dart
├── linux
├── macos
├── pubspec.lock
├── pubspec.yaml
├── test
├── web
└── windows
