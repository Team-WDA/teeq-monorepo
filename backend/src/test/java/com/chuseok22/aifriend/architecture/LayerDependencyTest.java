package com.chuseok22.aifriend.architecture;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;
import static com.tngtech.archunit.library.dependencies.SlicesRuleDefinition.slices;

import com.tngtech.archunit.core.importer.ImportOption;
import com.tngtech.archunit.junit.AnalyzeClasses;
import com.tngtech.archunit.junit.ArchTest;
import com.tngtech.archunit.lang.ArchRule;

@AnalyzeClasses(packages = "com.chuseok22.aifriend", importOptions = ImportOption.DoNotIncludeTests.class)
class LayerDependencyTest {

    @ArchTest
    static final ArchRule coreMustNotDependOnApplicationOrInfrastructure =
        noClasses().that().resideInAPackage("..core..")
            .should().dependOnClassesThat().resideInAnyPackage("..application..", "..infrastructure..")
            .allowEmptyShould(true);

    @ArchTest
    static final ArchRule applicationMustNotDependOnInfrastructure =
        noClasses().that().resideInAPackage("..application..")
            .should().dependOnClassesThat().resideInAPackage("..infrastructure..")
            .allowEmptyShould(true);

    @ArchTest
    static final ArchRule domainsMustBeFreeOfCycles =
        slices().matching("com.chuseok22.aifriend.(*)..")
            .should().beFreeOfCycles()
            .allowEmptyShould(true);

}
