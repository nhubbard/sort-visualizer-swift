#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <Security/Authorization.h>
#import <objc/runtime.h>
#import <spawn.h>
#import <fcntl.h>
#import <signal.h>
#import <sys/wait.h>
#import <unistd.h>
extern char **environ;
extern BOOL PFTInitializeSharedFrameworks(NSUInteger, id);

// These reflection helpers are gated by environment variables in the main
// bridge. They remain here so a new Xcode build can be surveyed without adding
// another executable or changing the stable Swift API.
static void dumpMethods(const char *className) {
  Class cls = objc_getClass(className);
  for (int kind = 0; kind < 2; kind++) {
    Class methodClass = kind ? object_getClass(cls) : cls;
    unsigned int count = 0;
    Method *methods = class_copyMethodList(methodClass, &count);
    for (unsigned int i = 0; i < count; i++) {
      fprintf(stderr, "%c[%s %s] %s\n", kind ? '+' : '-', className,
              sel_getName(method_getName(methods[i])), method_getTypeEncoding(methods[i]));
    }
    free(methods);
  }
}

static void printIssues(id accumulator) {
  for (id issue in [accumulator valueForKey:@"allErrorsAndWarningsSortedByTime"]) {
    fprintf(stderr, "issue: %s\n", [[issue valueForKey:@"message"] UTF8String]);
  }
}

static void terminateSpawnedTarget(pid_t pid) {
  if (pid <= 0) return;
  kill(pid, SIGTERM);
  for (int attempt = 0; attempt < 50; attempt++) {
    pid_t result = waitpid(pid, NULL, WNOHANG);
    if (result == pid || result == -1) return;
    usleep(10000);
  }
  // Only processes created by this probe reach this helper.
  kill(pid, SIGKILL);
  waitpid(pid, NULL, 0);
}

@interface XRTrace : NSObject
+ (id)templateItemMatchingName:(NSString *)name;
- (BOOL)loadTemplate:(NSURL *)templateURL outputURL:(NSURL *)outputURL preserveRunHistory:(BOOL)preserve error:(NSError **)error;
- (BOOL)startCommand:(id)command;
- (BOOL)isRunning;
- (void)endCommandWithReason:(NSUInteger)reason;
- (BOOL)saveDocument:(NSURL *)outputURL error:(NSError **)error;
- (NSURL *)outputURL;
- (void)setOutputURL:(NSURL *)outputURL;
- (id)currentCommand;
- (id)templateRecordCommand;
- (id)nextRecordingIssues;
- (id)instrumentsForNextRun;
- (id)runIssueAccumulator;
- (NSUInteger)runIssueErrorCountForCurrentRun;
- (void)close;
@end

@interface XRTemplateItem : NSObject
- (NSURL *)templateURL;
@end

@interface XRLocalDevice : NSObject
+ (id)sharedDevice;
@end

@interface XRDeviceDiscovery : NSObject
+ (NSArray *)availableDevices;
+ (void)enableListeningOnDiscoveryImplementations;
@end

@interface DTServiceHubClient : NSObject
+ (id)localDeviceConnectionWithError:(NSError **)error;
+ (NSString *)serviceHubBinaryPath;
@end

@interface DTInstrumentServer : NSObject
+ (void)takeOwnershipOfSharedAuthorization:(AuthorizationRef)authorization;
@end

@interface PFTProcess : NSObject
- (id)initWithDevice:(id)device path:(NSString *)path bundleIdentifier:(NSString *)bundleIdentifier pid:(int)pid;
+ (NSInteger)targetTypeForProcess:(id)process;
@end

@interface PFTInstrumentCommand : NSObject
- (id)initWithTrace:(XRTrace *)trace;
- (void)setTargetDevice:(id)device;
- (void)setTargetType:(NSInteger)type;
- (void)setTarget:(id)target;
- (void)setCommandPurpose:(unsigned int)purpose;
- (unsigned int)commandPurpose;
- (NSInteger)targetType;
- (id)target;
- (id)targetDevice;
- (id)deepCopy;
- (id)recordingControlState;
- (id)recordingOptions;
@end

@interface XRRecordingOptions : NSObject
- (BOOL)supportsImmediateMode;
- (BOOL)supportsDeferredMode;
- (BOOL)supportsWindowedMode;
- (NSUInteger)recordingMode;
@end

@interface PFTInstrumentRegistry : NSObject
+ (id)sharedInstrumentRegistry;
+ (id)defaultInstrumentRegistry;
- (NSArray *)allTypes;
- (NSArray *)availableTypes;
- (void)addTypesFromPackage:(id)package;
@end

@interface PFTInstrumentList : NSObject
- (NSArray *)allInstruments;
- (BOOL)addInstrumentWithIdentifier:(NSString *)identifier;
- (BOOL)allInstrumentsSupportTargetType:(NSInteger)type forDevice:(id)device;
- (BOOL)verifyCommand:(id)command error:(NSError **)error;
@end

@interface XRInstrument : NSObject
- (id)currentRecordSettingsDetailMetaUI;
- (id)recordingParametersInScope;
- (id)recordingControlState;
- (id)optionsDescription;
- (id)recordingControlState;
- (id)traceTemplateData;
@end

@interface XRPackageManager : NSObject
+ (id)sharedPackageManager;
- (id)loadPackageAtURL:(NSURL *)url loadModelerDefinitions:(BOOL)loadModelers error:(NSError **)error;
- (id)packages;
@end

int instruments_prepare(void) {
  // Mode 8 loads the modern native instrument packages in Xcode 27. Modes 0
  // and 1 left CPU Profiler represented by a deprecated stub during discovery.
  NSUInteger mode = getenv("INSTRUMENTS_MODE") ? strtoul(getenv("INSTRUMENTS_MODE"), NULL, 0) : 8;
  fprintf(stderr, "framework initialization mode: %lu\n", (unsigned long)mode);
  return PFTInitializeSharedFrameworks(mode, [NSObject new]) ? 0 : 10;
}

char *instruments_template_path(const char *name) {
  XRTemplateItem *item = [XRTrace templateItemMatchingName:@(name)];
  const char *path = item.templateURL.path.UTF8String;
  return path ? strdup(path) : NULL;
}

int instruments_record_with_callbacks(const char *pidOrDash,
                                     const char *executablePath,
                                     const char *outputPath,
                                     const char *requestedTemplate,
                                     const char *additionalIdentifiers,
                                     const char *configuredTemplatePath,
                                     const char *nativeOptionSpecifications,
                                     double durationSeconds,
                                     void (*onStarted)(void *),
                                     int (*shouldStop)(void *), void *context) {
  @autoreleasepool {
    // Phase 1: initialize the private framework graph and optionally serve
    // reflection-only discovery requests.
    if (instruments_prepare() != 0) return 10;
    if (getenv("INSTRUMENTS_DUMP_CLASSES")) {
      NSString *names = @(getenv("INSTRUMENTS_DUMP_CLASSES"));
      for (NSString *name in [names componentsSeparatedByString:@","]) {
        dumpMethods(name.UTF8String);
      }
      return 0;
    }
    if (!pidOrDash || !executablePath || !outputPath || durationSeconds <= 0) {
      fprintf(stderr, "invalid recording arguments\n");
      return 2;
    }
    // Phase 2: resolve the target. A dash launches a child; an integer attaches
    // to an existing process. Child stdio goes to /dev/null so a noisy fixture
    // cannot flood the host or its caller's captured output.
    pid_t pid = atoi(pidOrDash);
    BOOL spawned = strcmp(pidOrDash, "-") == 0;
    if (spawned) {
      char *const args[] = {(char *)executablePath, "30", NULL};
      posix_spawn_file_actions_t actions;
      int initResult = posix_spawn_file_actions_init(&actions);
      int actionsResult = initResult;
      if (!actionsResult) actionsResult = posix_spawn_file_actions_addopen(
          &actions, STDIN_FILENO, "/dev/null", O_RDONLY, 0);
      if (!actionsResult) actionsResult = posix_spawn_file_actions_addopen(
          &actions, STDOUT_FILENO, "/dev/null", O_WRONLY, 0);
      if (!actionsResult) actionsResult = posix_spawn_file_actions_addopen(
          &actions, STDERR_FILENO, "/dev/null", O_WRONLY, 0);
      int spawnResult = actionsResult ?: posix_spawn(
          &pid, executablePath, &actions, NULL, args, environ);
      if (!initResult) posix_spawn_file_actions_destroy(&actions);
      if (spawnResult) {
        fprintf(stderr, "posix_spawn failed: %d\n", spawnResult);
        return 2;
      }
    }
    fprintf(stderr, "target pid: %d\n", pid);
    // Transfer an AuthorizationRef to DTInstrumentServer before connecting to
    // DTServiceHub. The standalone ad hoc host reaches this code but still
    // cannot acquire kernel trace resources; the signed carrier can.
    if (!getenv("INSTRUMENTS_NO_AUTH")) {
      AuthorizationRef authorization = NULL;
      OSStatus authorizationResult = AuthorizationCreate(NULL, NULL, kAuthorizationFlagDefaults, &authorization);
      fprintf(stderr, "authorization create: %d ref: %p\n", (int)authorizationResult, authorization);
      if (authorizationResult == errAuthorizationSuccess) {
        [DTInstrumentServer takeOwnershipOfSharedAuthorization:authorization];
      }
    }
    [XRDeviceDiscovery enableListeningOnDiscoveryImplementations];
    fprintf(stderr, "available devices: %s\n", [XRDeviceDiscovery availableDevices].description.UTF8String);
    NSError *hubError = nil;
    id hubConnection = [DTServiceHubClient localDeviceConnectionWithError:&hubError];
    fprintf(stderr, "hub binary: %s connection: %s error: %s\n", [DTServiceHubClient serviceHubBinaryPath].UTF8String, [hubConnection description].UTF8String, hubError.description.UTF8String);
    if (!hubConnection) {
      fprintf(stderr, "DTServiceHub unavailable; no trace will be recorded.\n");
      if (spawned) {
        terminateSpawnedTarget(pid);
      }
      return 7;
    }
    // Phase 3: load either the installed template or the disposable archive
    // patched by Swift. Installed Xcode content is never modified in place.
    NSString *templateName = requestedTemplate ? @(requestedTemplate) : @"CPU Profiler";
    XRTemplateItem *item = [XRTrace templateItemMatchingName:templateName];
    NSURL *templateURL = configuredTemplatePath && configuredTemplatePath[0]
        ? [NSURL fileURLWithPath:@(configuredTemplatePath)]
        : getenv("INSTRUMENTS_TEMPLATE_PATH")
        ? [NSURL fileURLWithPath:@(getenv("INSTRUMENTS_TEMPLATE_PATH"))]
        : item.templateURL;
    fprintf(stderr, "template: %s (%s)\n", templateName.UTF8String, templateURL.path.UTF8String);
    if (!templateURL) return 3;
    XRTrace *trace = [XRTrace new];
    NSURL *outputURL = [NSURL fileURLWithPath:@(outputPath)];
    NSError *error = nil;
    if (![[NSFileManager defaultManager] createDirectoryAtURL:outputURL withIntermediateDirectories:YES attributes:nil error:&error]) {
      fprintf(stderr, "cannot create trace directory: %s\n", error.description.UTF8String);
      return 4;
    }
    BOOL loaded = [trace loadTemplate:templateURL outputURL:outputURL preserveRunHistory:NO error:&error];
    fprintf(stderr, "loaded: %d outputURL: %s error: %s\n", loaded, trace.outputURL.description.UTF8String, error.description.UTF8String);
    PFTInstrumentRegistry *registry = [PFTInstrumentRegistry sharedInstrumentRegistry];
    fprintf(stderr, "registry types: %lu available: %lu\n", (unsigned long)registry.allTypes.count, (unsigned long)registry.availableTypes.count);
    if (getenv("INSTRUMENTS_DUMP_REGISTRY_TYPES")) {
      for (id type in registry.availableTypes) {
        id name = nil;
        @try { name = [type valueForKey:@"displayName"]; } @catch (NSException *exception) {}
        fprintf(stderr, "registry type: %s / %s\n", [name description].UTF8String,
                [[type valueForKey:@"identifier"] description].UTF8String);
      }
    }
    // Phase 4: compose additional instruments and apply option JSON to each
    // native recording-control state. Archive-backed settings were already
    // patched into configuredTemplatePath by TraceSettings.swift.
    id nextInstruments = trace.instrumentsForNextRun;
    const char *additions = getenv("INSTRUMENTS_SURVEY_ADD_INSTRUMENT")
        ?: (additionalIdentifiers ? additionalIdentifiers : getenv("INSTRUMENTS_ADD_INSTRUMENTS"));
    if (additions && additions[0]) {
      NSString *identifiers = @(additions);
      for (NSString *identifier in [identifiers componentsSeparatedByString:@","]) {
        BOOL added = [(PFTInstrumentList *)nextInstruments addInstrumentWithIdentifier:identifier];
        fprintf(stderr, "add instrument %s: %d\n", identifier.UTF8String, added);
        if (!added) {
          [trace close];
          if (spawned) terminateSpawnedTarget(pid);
          return 11;
        }
      }
    }
    fprintf(stderr, "template instruments class: %s value: %s\n", class_getName([nextInstruments class]), [nextInstruments description].UTF8String);
    const char *nativeOptions = nativeOptionSpecifications
        ? nativeOptionSpecifications : getenv("INSTRUMENTS_SET_NATIVE_OPTIONS");
    NSArray<NSString *> *nativeSettings = nativeOptions && nativeOptions[0]
        ? [@(nativeOptions) componentsSeparatedByString:@";"] : @[];
    NSUInteger appliedNativeSettings = 0;
    for (id instrument in [(PFTInstrumentList *)nextInstruments allInstruments]) {
      id type = [instrument valueForKey:@"type"];
      fprintf(stderr, "instrument: %s type: %s / %s deprecated: %s\n", [[instrument valueForKey:@"displayName"] UTF8String], class_getName([type class]), [[type valueForKey:@"identifier"] UTF8String], [[type valueForKey:@"deprecated"] description].UTF8String);
      if (getenv("INSTRUMENTS_DUMP_LOADED_INSTRUMENT")) dumpMethods(class_getName([instrument class]));
      if (getenv("INSTRUMENTS_DUMP_OPTIONS")) {
        id options = [(XRInstrument *)instrument currentRecordSettingsDetailMetaUI];
        fprintf(stderr, "options for %s (%s): %s\n", [[instrument valueForKey:@"displayName"] UTF8String], class_getName([options class]), [options description].UTF8String);
        for (NSString *key in @[@"recordingParametersInScope", @"recordingControlState", @"optionsDescription"]) {
          id value = [instrument valueForKey:key];
          fprintf(stderr, "  %s (%s): %s\n", key.UTF8String, class_getName([value class]), [value description].UTF8String);
        }
      }
      if (getenv("INSTRUMENTS_DUMP_TEMPLATE_DATA")) {
        id templateData = [(XRInstrument *)instrument traceTemplateData];
        NSString *description = [templateData description];
        fprintf(stderr, "template data for %s (%s): %.1200s\n",
                [[instrument valueForKey:@"displayName"] UTF8String],
                class_getName([templateData class]), description.UTF8String);
      }
      if (nativeSettings.count) {
        for (NSString *setting in nativeSettings) {
          NSRange separator = [setting rangeOfString:@"|"];
          if (separator.location == NSNotFound ||
              ![[[instrument valueForKey:@"displayName"] description]
                  isEqualToString:[setting substringToIndex:separator.location]]) continue;
          NSData *encoded = [[setting substringFromIndex:separator.location + 1]
              dataUsingEncoding:NSUTF8StringEncoding];
          id state = [(XRInstrument *)instrument recordingControlState];
          @try {
            [state setValue:encoded forKey:@"optionsEncoded"];
            appliedNativeSettings++;
            fprintf(stderr, "set native options for %s\n",
                    [[instrument valueForKey:@"displayName"] UTF8String]);
          } @catch (NSException *exception) {
            fprintf(stderr, "native option setter failed: %s\n", exception.description.UTF8String);
            [trace close];
            if (spawned) terminateSpawnedTarget(pid);
            return 12;
          }
        }
      }
      if (getenv("INSTRUMENTS_DUMP_SWITCH_KEYS")) {
        id state = [(XRInstrument *)instrument recordingControlState];
        for (NSString *key in [@(getenv("INSTRUMENTS_DUMP_SWITCH_KEYS")) componentsSeparatedByString:@","]) {
          id value = nil;
          @try { value = [state valueForKey:key]; } @catch (NSException *exception) {}
          fprintf(stderr, "instrument switch value %s %s: %s\n",
                  [[instrument valueForKey:@"displayName"] UTF8String], key.UTF8String,
                  [value description].UTF8String);
        }
      }
      if (getenv("INSTRUMENTS_SET_INSTRUMENT_SWITCH")) {
        NSString *setting = @(getenv("INSTRUMENTS_SET_INSTRUMENT_SWITCH"));
        NSArray<NSString *> *parts = [setting componentsSeparatedByString:@"="];
        if (parts.count == 3 && [[instrument valueForKey:@"displayName"] isEqualToString:parts[0]]) {
          id state = [(XRInstrument *)instrument recordingControlState];
          NSString *key = parts[1];
          fprintf(stderr, "instrument switch %s before: %s\n", key.UTF8String, [[state valueForKey:key] description].UTF8String);
          [state setValue:@([parts[2] longLongValue]) forKey:key];
          fprintf(stderr, "instrument switch %s after: %s\n", key.UTF8String, [[state valueForKey:key] description].UTF8String);
        }
      }
    }
    if (appliedNativeSettings != nativeSettings.count) {
      fprintf(stderr, "native option target missing: applied %lu of %lu\n",
              (unsigned long)appliedNativeSettings, (unsigned long)nativeSettings.count);
      [trace close];
      if (spawned) terminateSpawnedTarget(pid);
      return 12;
    }
    if (getenv("INSTRUMENTS_CHECK_TARGET_TYPES")) {
      id localDevice = [XRLocalDevice sharedDevice];
      for (NSInteger type = 0; type <= 3; type++) {
        fprintf(stderr, "target type %ld supported: %d\n", (long)type,
                [(PFTInstrumentList *)nextInstruments allInstrumentsSupportTargetType:type forDevice:localDevice]);
      }
    }
    if (getenv("INSTRUMENTS_CHECK_RECORDING_MODES")) {
      XRRecordingOptions *options = [(PFTInstrumentCommand *)trace.templateRecordCommand recordingOptions];
      fprintf(stderr, "recording modes immediate=%d deferred=%d windowed=%d current=%lu\n",
              options.supportsImmediateMode, options.supportsDeferredMode,
              options.supportsWindowedMode, (unsigned long)options.recordingMode);
    }
    if (getenv("INSTRUMENTS_INSPECT_ONLY")) {
      [trace close];
      if (spawned) {
        terminateSpawnedTarget(pid);
      }
      return 0;
    }
    if (!loaded) return 4;
    [trace setOutputURL:outputURL];
    fprintf(stderr, "set outputURL: %s template command: %s\n", trace.outputURL.description.UTF8String, [trace.templateRecordCommand description].UTF8String);
    // Phase 5: reject target-incompatible compositions before starting, then
    // bind a deep copy of the template command to the local process.
    id device = [XRLocalDevice sharedDevice];
    PFTProcess *process = [[PFTProcess alloc] initWithDevice:device path:@(executablePath) bundleIdentifier:nil pid:pid];
    NSInteger targetType = [PFTProcess targetTypeForProcess:process];
    fprintf(stderr, "device: %s target pid: %d targetType: %ld\n", [device description].UTF8String, pid, (long)targetType);
    NSInteger requestedTargetType = getenv("INSTRUMENTS_ALL_PROCESSES") ? 1 : targetType;
    if (![(PFTInstrumentList *)nextInstruments allInstrumentsSupportTargetType:requestedTargetType forDevice:device]) {
      fprintf(stderr, "selected instruments reject target type %ld\n", (long)requestedTargetType);
      [trace close];
      [[NSFileManager defaultManager] removeItemAtURL:outputURL error:NULL];
      if (spawned) terminateSpawnedTarget(pid);
      return 15;
    }
    if (getenv("INSTRUMENTS_SET_TEMPLATE_SWITCH")) {
      NSString *setting = @(getenv("INSTRUMENTS_SET_TEMPLATE_SWITCH"));
      NSArray<NSString *> *parts = [setting componentsSeparatedByString:@"="];
      if (parts.count != 2) return 12;
      id state = [(PFTInstrumentCommand *)trace.templateRecordCommand recordingControlState];
      fprintf(stderr, "template switch %s before: %s\n", parts[0].UTF8String, [[state valueForKey:parts[0]] description].UTF8String);
      [state setValue:@([parts[1] longLongValue]) forKey:parts[0]];
      fprintf(stderr, "template switch %s after: %s\n", parts[0].UTF8String, [[state valueForKey:parts[0]] description].UTF8String);
    }
    PFTInstrumentCommand *command = trace.templateRecordCommand ? [trace.templateRecordCommand deepCopy] : [[PFTInstrumentCommand alloc] initWithTrace:trace];
    fprintf(stderr, "initial purpose: %u targetType: %ld target: %s device: %s\n", command.commandPurpose, (long)command.targetType, [command.target description].UTF8String, [command.targetDevice description].UTF8String);
    [command setTargetDevice:device];
    if (getenv("INSTRUMENTS_ALL_PROCESSES")) {
      [command setTargetType:1];
      [command setTarget:nil];
    } else {
      [command setTargetType:targetType];
      [command setTarget:process];
    }
    if (getenv("INSTRUMENTS_SET_SWITCH")) {
      NSString *setting = @(getenv("INSTRUMENTS_SET_SWITCH"));
      NSRange separator = [setting rangeOfString:@"="];
      if (separator.location == NSNotFound) return 12;
      NSString *key = [setting substringToIndex:separator.location];
      NSString *raw = [setting substringFromIndex:separator.location + 1];
      NSNumber *value = @([raw longLongValue]);
      id state = [command recordingControlState];
      @try {
        fprintf(stderr, "switch %s before: %s\n", key.UTF8String, [[state valueForKey:key] description].UTF8String);
        [state setValue:value forKey:key];
        fprintf(stderr, "switch %s after: %s\n", key.UTF8String, [[state valueForKey:key] description].UTF8String);
      } @catch (NSException *exception) {
        fprintf(stderr, "switch setting exception: %s\n", exception.description.UTF8String);
        [trace close];
        if (spawned) terminateSpawnedTarget(pid);
        return 12;
      }
    }
    if (getenv("INSTRUMENTS_VERIFY_ONLY")) {
      NSError *verificationError = nil;
      BOOL verified = [(PFTInstrumentList *)nextInstruments verifyCommand:command error:&verificationError];
      fprintf(stderr, "verify command: %d error: %s\n", verified, verificationError.description.UTF8String);
      [trace close];
      if (spawned) terminateSpawnedTarget(pid);
      return verified ? 0 : 13;
    }
    // Phase 6: start and wait for the real isRunning transition. READY must not
    // be emitted earlier or a microtargeted operation can finish in preflight.
    BOOL started = [trace startCommand:command];
    fprintf(stderr, "started: %d running: %d\n", started, trace.isRunning);
    if (!started) return 5;
    NSDate *until = [NSDate dateWithTimeIntervalSinceNow:10];
    while (!trace.isRunning && [until timeIntervalSinceNow] > 0) {
      [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
    fprintf(stderr, "after preflight running: %d command: %s errors: %lu next errors: %s run issues: %s\n", trace.isRunning, [trace.currentCommand description].UTF8String, (unsigned long)trace.runIssueErrorCountForCurrentRun, [[trace.nextRecordingIssues valueForKey:@"errors"] description].UTF8String, [[trace.runIssueAccumulator valueForKey:@"allErrorsAndWarningsSortedByTime"] description].UTF8String);
    if (getenv("INSTRUMENTS_SET_SWITCH")) {
      NSString *setting = @(getenv("INSTRUMENTS_SET_SWITCH"));
      NSString *key = [setting componentsSeparatedByString:@"="].firstObject;
      id currentState = [(PFTInstrumentCommand *)trace.currentCommand recordingControlState];
      fprintf(stderr, "switch %s in current command: %s\n", key.UTF8String, [[currentState valueForKey:key] description].UTF8String);
    }
    if (!trace.isRunning) {
      fprintf(stderr, "recording never started\n");
      [trace close];
      if (spawned) {
        terminateSpawnedTarget(pid);
      }
      return 8;
    }
    if (onStarted) onStarted(context);
    NSDate *recordingStart = [NSDate date];
    until = [NSDate dateWithTimeIntervalSinceNow:durationSeconds];
    BOOL stoppedByClient = NO;
    while (trace.isRunning && [until timeIntervalSinceNow] > 0) {
      if (shouldStop && -[recordingStart timeIntervalSinceNow] >= 0.05 && shouldStop(context)) {
        stoppedByClient = YES;
        break;
      }
      [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    }
    // Phase 7: stop at the duration cap or the client's event boundary, wait
    // for Instruments to finish, save, close, and reap only children we made.
    [trace endCommandWithReason:0];
    until = [NSDate dateWithTimeIntervalSinceNow:15];
    while (trace.isRunning && [until timeIntervalSinceNow] > 0) {
      [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
    BOOL stopTimedOut = trace.isRunning;
    fprintf(stderr, "before save running: %d outputURL: %s errors: %lu run issues: %s\n", trace.isRunning, trace.outputURL.description.UTF8String, (unsigned long)trace.runIssueErrorCountForCurrentRun, [[trace.runIssueAccumulator valueForKey:@"allErrorsAndWarningsSortedByTime"] description].UTF8String);
    printIssues(trace.runIssueAccumulator);
    BOOL reachedRequestedDuration = stoppedByClient ||
        -[recordingStart timeIntervalSinceNow] >= durationSeconds * 0.95;
    NSUInteger recordingErrorCount = trace.runIssueErrorCountForCurrentRun;
    error = nil;
    BOOL saved = [trace saveDocument:outputURL error:&error];
    fprintf(stderr, "saved: %d error: %s\n", saved, error.description.UTF8String);
    [trace close];
    if (spawned) {
      terminateSpawnedTarget(pid);
    }
    return !saved ? 6 : (stopTimedOut ? 14 :
        (recordingErrorCount || !reachedRequestedDuration ? 9 : 0));
  }
}

int instruments_record_with_callback(const char *pidOrDash,
                                     const char *executablePath,
                                     const char *outputPath,
                                     const char *requestedTemplate,
                                     double durationSeconds,
                                     void (*onStarted)(void *), void *context) {
  return instruments_record_with_callbacks(pidOrDash, executablePath, outputPath,
                                           requestedTemplate, NULL, NULL, NULL, durationSeconds,
                                           onStarted, NULL, context);
}

int instruments_record(const char *pidOrDash, const char *executablePath,
                       const char *outputPath, const char *requestedTemplate,
                       double durationSeconds) {
  return instruments_record_with_callback(pidOrDash, executablePath, outputPath,
                                          requestedTemplate, durationSeconds,
                                          NULL, NULL);
}

int instruments_probe_run(int argc, const char *argv[]) {
  if (argc != 4) {
    fprintf(stderr, "usage: probe pid|- executable-path output.trace\n");
    return 2;
  }
  const char *templateName = getenv("INSTRUMENTS_TEMPLATE") ?: "CPU Profiler";
  double duration = getenv("INSTRUMENTS_DURATION") ? atof(getenv("INSTRUMENTS_DURATION")) : 2;
  return instruments_record(argv[1], argv[2], argv[3], templateName, duration);
}

#ifndef INSTRUMENTS_INJECT_BUILD
int main(int argc, const char *argv[]) {
  return instruments_probe_run(argc, argv);
}
#endif
