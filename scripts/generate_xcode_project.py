#!/usr/bin/env python3
"""Generate a minimal Xcode project for the Sustenance iOS app."""

from __future__ import annotations

import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "Sustenance"
PROJECT_PATH = ROOT / "Sustenance.xcodeproj" / "project.pbxproj"

MARKETING_VERSION = "1.0"
CURRENT_PROJECT_VERSION = "4"
SIGNING_CONFIG_PATH = ROOT / "Signing.local.xcconfig"


def load_development_team() -> str | None:
    if SIGNING_CONFIG_PATH.exists():
        for line in SIGNING_CONFIG_PATH.read_text(encoding="utf-8").splitlines():
            stripped = line.split("//", 1)[0].strip()
            if stripped.startswith("DEVELOPMENT_TEAM"):
                _, _, value = stripped.partition("=")
                value = value.strip()
                if value:
                    return value
    return None

APP_FILES = {
    "App": ["Sustenance/App/SustenanceApp.swift"],
    "Models": [
        "Sustenance/Models/EnergyLevel.swift",
        "Sustenance/Models/StorageLocation.swift",
        "Sustenance/Models/SafetyStatus.swift",
        "Sustenance/Models/RecipeIngredient.swift",
        "Sustenance/Models/SuggestionScore.swift",
        "Sustenance/Models/Recipe.swift",
        "Sustenance/Models/PantryItem.swift",
        "Sustenance/Models/SafetyProfile.swift",
        "Sustenance/Models/DietPreference.swift",
        "Sustenance/Models/MealLogEntry.swift",
        "Sustenance/Models/ShoppingListItem.swift",
    ],
    "Services": [
        "Sustenance/Services/AppDataReset.swift",
        "Sustenance/Services/ICloudAccountStatus.swift",
        "Sustenance/Services/IngredientMatcher.swift",
        "Sustenance/Services/SuggestionEngine.swift",
        "Sustenance/Services/MealSuggestions.swift",
        "Sustenance/Services/MealTrackingService.swift",
        "Sustenance/Services/RecipeLibraryFilter.swift",
        "Sustenance/Services/ShoppingListService.swift",
        "Sustenance/Services/MarkdownRecipeParser.swift",
        "Sustenance/Services/RecipePhotoProcessor.swift",
    ],
    "Data": [
        "Sustenance/Data/AppConfiguration.swift",
        "Sustenance/Data/AppPreferences.swift",
        "Sustenance/Data/SeedData.swift",
        "Sustenance/Data/DataSeeder.swift",
        "Sustenance/Data/SustenanceMigrationPlan.swift",
    ],
    "Views": [
        "Sustenance/Views/FirstRunTipsView.swift",
        "Sustenance/Views/WelcomeLoadingView.swift",
        "Sustenance/Views/ContentView.swift",
        "Sustenance/Views/TodayView.swift",
        "Sustenance/Views/SafeMealsView.swift",
        "Sustenance/Views/RecipeDetailView.swift",
        "Sustenance/Views/RecipesView.swift",
        "Sustenance/Views/RecipeEditorView.swift",
        "Sustenance/Views/RecipePhotoView.swift",
        "Sustenance/Views/PantryView.swift",
        "Sustenance/Views/PantryItemEditorView.swift",
        "Sustenance/Views/SettingsView.swift",
        "Sustenance/Views/AppearanceModePicker.swift",
        "Sustenance/Views/DietPreferencesEditor.swift",
        "Sustenance/Views/TagListEditor.swift",
        "Sustenance/Views/EnergySelectorView.swift",
        "Sustenance/Views/SuggestionCardView.swift",
        "Sustenance/Views/SafetyStatusBadge.swift",
        "Sustenance/Views/IngredientGroupView.swift",
        "Sustenance/Views/SustenanceAddButton.swift",
        "Sustenance/Views/SustenancePlaceholder.swift",
        "Sustenance/Views/ShoppingListView.swift",
        "Sustenance/Views/MealCalendarView.swift",
        "Sustenance/Views/LogMealSheet.swift",
        "Sustenance/Views/MealRepeatReminderBanner.swift",
        "Sustenance/Views/RecipeMarkdownImportView.swift",
    ],
    "Theme": [
        "Sustenance/Theme/SustenanceTheme.swift",
        "Sustenance/Theme/EnergyLevelColors.swift",
        "Sustenance/Theme/AppearanceMode.swift",
        "Sustenance/Theme/SustenanceIllustrationStyle.swift",
    ],
}

TEST_FILES = [
    "SustenanceTests/SuggestionEngineTests.swift",
    "SustenanceTests/DietPreferenceMatcherTests.swift",
    "SustenanceTests/MealTrackingServiceTests.swift",
    "SustenanceTests/RecipePhotoProcessorTests.swift",
    "SustenanceTests/MarkdownRecipeParserTests.swift",
]


def uid() -> str:
    return uuid.uuid4().hex[:24].upper()


def pbx_group(group_id: str, name: str, children: list[str], path: str | None = None) -> str:
    child_list = ", ".join(children)
    path_line = f" path = {name};" if path else ""
    return (
        f"\t\t{group_id} /* {name} */ = {{isa = PBXGroup; children = ({child_list});"
        f"{path_line} sourceTree = \"<group>\"; }};"
    )


def main() -> None:
    all_app_paths = [path for paths in APP_FILES.values() for path in paths]
    development_team = load_development_team()
    if development_team is None:
        print(
            "Warning: no DEVELOPMENT_TEAM found. Copy "
            "Sustenance/Signing.local.xcconfig.example to Signing.local.xcconfig "
            "and set your team ID before archiving."
        )

    ids = {
        "project": uid(),
        "main_group": uid(),
        "sustenance_group": uid(),
        "tests_group": uid(),
        "products": uid(),
        "app_product": uid(),
        "test_product": uid(),
        "app_target": uid(),
        "test_target": uid(),
        "sources_phase": uid(),
        "resources_phase": uid(),
        "test_sources_phase": uid(),
        "frameworks_phase": uid(),
        "test_frameworks_phase": uid(),
        "assets": uid(),
        "assets_build": uid(),
        "proxy": uid(),
        "test_dependency": uid(),
        "project_config_list": uid(),
        "app_config_list": uid(),
        "test_config_list": uid(),
        "debug_project": uid(),
        "release_project": uid(),
        "debug_target": uid(),
        "release_target": uid(),
        "debug_tests": uid(),
        "release_tests": uid(),
    }

    subgroup_ids = {name: uid() for name in APP_FILES}
    file_refs = {path: uid() for path in all_app_paths + TEST_FILES}
    build_files = {path: uid() for path in all_app_paths}
    test_build_files = {path: uid() for path in TEST_FILES}

    lines: list[str] = [
        "// !$*UTF8*$!",
        "{",
        "\tarchiveVersion = 1;",
        "\tclasses = {",
        "\t};",
        "\tobjectVersion = 56;",
        "\tobjects = {",
        "",
        "/* Begin PBXBuildFile section */",
    ]

    for path in all_app_paths:
        name = Path(path).name
        lines.append(
            f"\t\t{build_files[path]} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_refs[path]} /* {name} */; }};"
        )
    lines.append(
        f"\t\t{ids['assets_build']} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {ids['assets']} /* Assets.xcassets */; }};"
    )
    for path in TEST_FILES:
        name = Path(path).name
        lines.append(
            f"\t\t{test_build_files[path]} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_refs[path]} /* {name} */; }};"
        )
    lines.extend(["/* End PBXBuildFile section */", ""])

    lines.extend([
        "/* Begin PBXContainerItemProxy section */",
        f"\t\t{ids['proxy']} /* PBXContainerItemProxy */ = {{isa = PBXContainerItemProxy; containerPortal = {ids['project']} /* Project object */; proxyType = 1; remoteGlobalIDString = {ids['app_target']}; remoteInfo = Sustenance; }};",
        "/* End PBXContainerItemProxy section */",
        "",
        "/* Begin PBXFileReference section */",
        f"\t\t{ids['app_product']} /* Sustenance.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = Sustenance.app; sourceTree = BUILT_PRODUCTS_DIR; }};",
        f"\t\t{ids['test_product']} /* SustenanceTests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = SustenanceTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};",
        f"\t\t{ids['assets']} /* Assets.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = \"<group>\"; }};",
    ])

    for path in all_app_paths + TEST_FILES:
        name = Path(path).name
        lines.append(
            f"\t\t{file_refs[path]} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {name}; sourceTree = \"<group>\"; }};"
        )
    lines.extend(["/* End PBXFileReference section */", ""])

    lines.extend([
        "/* Begin PBXFrameworksBuildPhase section */",
        f"\t\t{ids['frameworks_phase']} /* Frameworks */ = {{isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = ( ); runOnlyForDeploymentPostprocessing = 0; }};",
        f"\t\t{ids['test_frameworks_phase']} /* Frameworks */ = {{isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = ( ); runOnlyForDeploymentPostprocessing = 0; }};",
        "/* End PBXFrameworksBuildPhase section */",
        "",
        "/* Begin PBXGroup section */",
        f"\t\t{ids['main_group']} = {{isa = PBXGroup; children = ({ids['sustenance_group']} /* Sustenance */, {ids['tests_group']} /* SustenanceTests */, {ids['products']} /* Products */); sourceTree = \"<group>\"; }};",
        f"\t\t{ids['products']} /* Products */ = {{isa = PBXGroup; children = ({ids['app_product']} /* Sustenance.app */, {ids['test_product']} /* SustenanceTests.xctest */); name = Products; sourceTree = \"<group>\"; }};",
    ])

    sustenance_children = [ids["assets"]] + [subgroup_ids[name] for name in APP_FILES]
    lines.append(
        f"\t\t{ids['sustenance_group']} /* Sustenance */ = {{isa = PBXGroup; children = ({', '.join(sustenance_children)}); path = Sustenance; sourceTree = \"<group>\"; }};"
    )

    for group_name, paths in APP_FILES.items():
        children = ", ".join(file_refs[path] for path in paths)
        lines.append(
            f"\t\t{subgroup_ids[group_name]} /* {group_name} */ = {{isa = PBXGroup; children = ({children}); path = {group_name}; sourceTree = \"<group>\"; }};"
        )

    test_children = ", ".join(file_refs[path] for path in TEST_FILES)
    lines.append(
        f"\t\t{ids['tests_group']} /* SustenanceTests */ = {{isa = PBXGroup; children = ({test_children}); path = SustenanceTests; sourceTree = \"<group>\"; }};"
    )
    lines.extend(["/* End PBXGroup section */", ""])

    app_source_entries = ", ".join(
        f"{build_files[path]} /* {Path(path).name} in Sources */" for path in all_app_paths
    )
    test_source_entries = ", ".join(
        f"{test_build_files[path]} /* {Path(path).name} in Sources */" for path in TEST_FILES
    )

    if development_team:
        app_target_attrs = (
            f"{ids['app_target']} = {{ CreatedOnToolsVersion = 16.0; "
            f"DevelopmentTeam = {development_team}; ProvisioningStyle = Automatic; }};"
        )
        test_target_attrs = (
            f"{ids['test_target']} = {{ CreatedOnToolsVersion = 16.0; "
            f"DevelopmentTeam = {development_team}; ProvisioningStyle = Automatic; "
            f"TestTargetID = {ids['app_target']}; }};"
        )
    else:
        app_target_attrs = f"{ids['app_target']} = {{ CreatedOnToolsVersion = 16.0; }};"
        test_target_attrs = (
            f"{ids['test_target']} = {{ CreatedOnToolsVersion = 16.0; "
            f"TestTargetID = {ids['app_target']}; }};"
        )

    lines.extend([
        "/* Begin PBXNativeTarget section */",
        f"\t\t{ids['app_target']} /* Sustenance */ = {{isa = PBXNativeTarget; buildConfigurationList = {ids['app_config_list']} /* Build configuration list for PBXNativeTarget \"Sustenance\" */; buildPhases = ({ids['sources_phase']} /* Sources */, {ids['frameworks_phase']} /* Frameworks */, {ids['resources_phase']} /* Resources */); buildRules = ( ); dependencies = ( ); name = Sustenance; productName = Sustenance; productReference = {ids['app_product']} /* Sustenance.app */; productType = \"com.apple.product-type.application\"; }};",
        f"\t\t{ids['test_target']} /* SustenanceTests */ = {{isa = PBXNativeTarget; buildConfigurationList = {ids['test_config_list']} /* Build configuration list for PBXNativeTarget \"SustenanceTests\" */; buildPhases = ({ids['test_sources_phase']} /* Sources */, {ids['test_frameworks_phase']} /* Frameworks */); buildRules = ( ); dependencies = ({ids['test_dependency']} /* PBXTargetDependency */); name = SustenanceTests; productName = SustenanceTests; productReference = {ids['test_product']} /* SustenanceTests.xctest */; productType = \"com.apple.product-type.bundle.unit-test\"; }};",
        "/* End PBXNativeTarget section */",
        "",
        "/* Begin PBXProject section */",
        f"\t\t{ids['project']} /* Project object */ = {{isa = PBXProject; attributes = {{BuildIndependentTargetsInParallel = 1; LastSwiftUpdateCheck = 1600; LastUpgradeCheck = 1600; TargetAttributes = {{ {app_target_attrs} {test_target_attrs} }}; }}; buildConfigurationList = {ids['project_config_list']} /* Build configuration list for PBXProject \"Sustenance\" */; compatibilityVersion = \"Xcode 14.0\"; developmentRegion = en; hasScannedForEncodings = 0; knownRegions = (en, Base); mainGroup = {ids['main_group']}; productRefGroup = {ids['products']} /* Products */; projectDirPath = \"\"; projectRoot = \"\"; targets = ({ids['app_target']} /* Sustenance */, {ids['test_target']} /* SustenanceTests */); }};",
        "/* End PBXProject section */",
        "",
        "/* Begin PBXResourcesBuildPhase section */",
        f"\t\t{ids['resources_phase']} /* Resources */ = {{isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = ({ids['assets_build']} /* Assets.xcassets in Resources */); runOnlyForDeploymentPostprocessing = 0; }};",
        "/* End PBXResourcesBuildPhase section */",
        "",
        "/* Begin PBXSourcesBuildPhase section */",
        f"\t\t{ids['sources_phase']} /* Sources */ = {{isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ({app_source_entries}); runOnlyForDeploymentPostprocessing = 0; }};",
        f"\t\t{ids['test_sources_phase']} /* Sources */ = {{isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ({test_source_entries}); runOnlyForDeploymentPostprocessing = 0; }};",
        "/* End PBXSourcesBuildPhase section */",
        "",
        "/* Begin PBXTargetDependency section */",
        f"\t\t{ids['test_dependency']} /* PBXTargetDependency */ = {{isa = PBXTargetDependency; target = {ids['app_target']} /* Sustenance */; targetProxy = {ids['proxy']} /* PBXContainerItemProxy */; }};",
        "/* End PBXTargetDependency section */",
        "",
        "/* Begin XCBuildConfiguration section */",
        build_config(ids["debug_project"], "Debug", project=True),
        build_config(ids["release_project"], "Release", project=True),
        build_config(ids["debug_target"], "Debug", bundle_id="com.draftandform.sustenance", development_team=development_team),
        build_config(ids["release_target"], "Release", bundle_id="com.draftandform.sustenance", development_team=development_team),
        build_config(ids["debug_tests"], "Debug", bundle_id="com.draftandform.sustenance.tests", test_host=True, development_team=development_team),
        build_config(ids["release_tests"], "Release", bundle_id="com.draftandform.sustenance.tests", test_host=True, development_team=development_team),
        "/* End XCBuildConfiguration section */",
        "",
        "/* Begin XCConfigurationList section */",
        f"\t\t{ids['project_config_list']} /* Build configuration list for PBXProject \"Sustenance\" */ = {{isa = XCConfigurationList; buildConfigurations = ({ids['debug_project']} /* Debug */, {ids['release_project']} /* Release */); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }};",
        f"\t\t{ids['app_config_list']} /* Build configuration list for PBXNativeTarget \"Sustenance\" */ = {{isa = XCConfigurationList; buildConfigurations = ({ids['debug_target']} /* Debug */, {ids['release_target']} /* Release */); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }};",
        f"\t\t{ids['test_config_list']} /* Build configuration list for PBXNativeTarget \"SustenanceTests\" */ = {{isa = XCConfigurationList; buildConfigurations = ({ids['debug_tests']} /* Debug */, {ids['release_tests']} /* Release */); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }};",
        "/* End XCConfigurationList section */",
        "\t};",
        f"\trootObject = {ids['project']} /* Project object */;",
        "}",
        "",
    ])

    PROJECT_PATH.parent.mkdir(parents=True, exist_ok=True)
    PROJECT_PATH.write_text("\n".join(lines), encoding="utf-8")
    print(f"Wrote {PROJECT_PATH}")

    write_scheme(ids)


def write_scheme(ids: dict[str, str]) -> None:
    scheme_path = ROOT / "Sustenance.xcodeproj" / "xcshareddata" / "xcschemes" / "Sustenance.xcscheme"
    scheme_path.parent.mkdir(parents=True, exist_ok=True)
    app_ref = f"""               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{ids['app_target']}"
               BuildableName = "Sustenance.app"
               BlueprintName = "Sustenance"
               ReferencedContainer = "container:Sustenance.xcodeproj\""""
    test_ref = f"""               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{ids['test_target']}"
               BuildableName = "SustenanceTests.xctest"
               BlueprintName = "SustenanceTests"
               ReferencedContainer = "container:Sustenance.xcodeproj\""""
    scheme_path.write_text(
        f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1600"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
{app_ref}>
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
         <TestableReference
            skipped = "NO"
            parallelizable = "YES">
            <BuildableReference
{test_ref}>
            </BuildableReference>
         </TestableReference>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
{app_ref}>
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
{app_ref}>
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
""",
        encoding="utf-8",
    )
    print(f"Wrote {scheme_path}")


def build_config(
    config_id: str,
    name: str,
    *,
    project: bool = False,
    bundle_id: str | None = None,
    test_host: bool = False,
    development_team: str | None = None,
) -> str:
    lines = [
        f"\t\t{config_id} /* {name} */ = {{",
        f"\t\t\tisa = XCBuildConfiguration;",
        f"\t\t\tbuildSettings = {{",
        f"\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;",
        f"\t\t\t\tCLANG_ENABLE_MODULES = YES;",
        f"\t\t\t\tCODE_SIGN_STYLE = Automatic;",
        f"\t\t\t\tCURRENT_PROJECT_VERSION = {CURRENT_PROJECT_VERSION};",
        f"\t\t\t\tENABLE_PREVIEWS = YES;",
        f"\t\t\t\tGENERATE_INFOPLIST_FILE = YES;",
        f"\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;",
        f"\t\t\t\tMARKETING_VERSION = {MARKETING_VERSION};",
        f"\t\t\t\tPRODUCT_NAME = \"$(TARGET_NAME)\";",
        f"\t\t\t\tSDKROOT = iphoneos;",
        f"\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;",
        f"\t\t\t\tSWIFT_VERSION = 5.0;",
        f"\t\t\t\tTARGETED_DEVICE_FAMILY = 1;",
    ]

    if project:
        if name == "Debug":
            lines.extend([
                "\t\t\t\tCOPY_PHASE_STRIP = NO;",
                "\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;",
                "\t\t\t\tENABLE_TESTABILITY = YES;",
                "\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;",
                "\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;",
                "\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;",
                "\t\t\t\tONLY_ACTIVE_ARCH = YES;",
                "\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;",
                "\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = \"-Onone\";",
            ])
        else:
            lines.extend([
                "\t\t\t\tCOPY_PHASE_STRIP = NO;",
                "\t\t\t\tDEBUG_INFORMATION_FORMAT = \"dwarf-with-dsym\";",
                "\t\t\t\tENABLE_NS_ASSERTIONS = NO;",
                "\t\t\t\tMTL_ENABLE_DEBUG_INFO = NO;",
                "\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;",
                "\t\t\t\tVALIDATE_PRODUCT = YES;",
            ])
    else:
        if development_team:
            lines.append(f"\t\t\t\tDEVELOPMENT_TEAM = {development_team};")
        lines.extend([
            "\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;",
            "\t\t\t\tCODE_SIGN_ENTITLEMENTS = Sustenance.entitlements;",
            "\t\t\t\tINFOPLIST_KEY_CFBundleDisplayName = Sustenance;",
            "\t\t\t\tINFOPLIST_KEY_CFBundleIconName = AppIcon;",
            "\t\t\t\tINFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO;",
            "\t\t\t\tINFOPLIST_KEY_LSApplicationCategoryType = \"public.app-category.food-and-drink\";",
            "\t\t\t\tINFOPLIST_KEY_NSPhotoLibraryUsageDescription = \"Choose photos to attach to your recipes.\";",
            "\t\t\t\tINFOPLIST_KEY_UILaunchScreen_Generation = YES;",
            "\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations = UIInterfaceOrientationPortrait;",
        ])
        if bundle_id:
            lines.append(f"\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = {bundle_id};")
        if test_host:
            lines.extend([
                "\t\t\t\tBUNDLE_LOADER = \"$(TEST_HOST)\";",
                "\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (\"$(inherited)\", \"@executable_path/Frameworks\", \"@loader_path/Frameworks\");",
                "\t\t\t\tTEST_HOST = \"$(BUILT_PRODUCTS_DIR)/Sustenance.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/Sustenance\";",
            ])
        else:
            lines.append("\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (\"$(inherited)\", \"@executable_path/Frameworks\");")

    lines.extend([
        "\t\t\t};",
        f"\t\t\tname = {name};",
        "\t\t};",
    ])
    return "\n".join(lines)


if __name__ == "__main__":
    main()
