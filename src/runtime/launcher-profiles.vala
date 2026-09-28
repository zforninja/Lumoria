namespace Lumoria.Runtime {

    public const string FEATURE_PROFILES = "profiles";
    public const string LAUNCHER_PROFILE_ID_PREFIX = "windower4-profile:";

    public string launcher_profile_entry_id (string profile_name) {
        if (profile_name.strip () == "") {
            return LAUNCHER_PROFILE_ID_PREFIX + "default";
        }
        return LAUNCHER_PROFILE_ID_PREFIX + Uri.escape_string (profile_name, null, true);
    }

    public string launcher_profile_display_label (string profile_name) {
        return profile_name.strip () == "" ? _("Default") : profile_name;
    }

    public string? launcher_profile_name_from_entry_id (string entrypoint_id) {
        if (!entrypoint_id.has_prefix (LAUNCHER_PROFILE_ID_PREFIX)) return null;
        var suffix = entrypoint_id.substring (LAUNCHER_PROFILE_ID_PREFIX.length);
        if (suffix == "" || suffix == "default") return "";
        return Uri.unescape_string (suffix);
    }

    public Gee.ArrayList<Models.Entrypoint> list_launcher_profile_entrypoints (ManifestContext ctx) {
        var list = new Gee.ArrayList<Models.Entrypoint> ();
        if (ctx.launcher == null || !ctx.launcher.supports_feature (FEATURE_PROFILES)) return list;

        var dir = launcher_dir_from_context (ctx);
        if (dir == "") return list;
        var settings = Path.build_filename (dir, "settings.xml");

        string xml_text;
        try {
            FileUtils.get_contents (settings, out xml_text);
        } catch (FileError e) {
            list.add (build_launcher_profile_entry (""));
            return list;
        }

        foreach (var name in parse_profile_names_from_xml (xml_text)) {
            list.add (build_launcher_profile_entry (name));
        }
        return list;
    }

    /*
     * Boot profiles: launchers such as Ashita v4 keep one `.ini` per character or
     * server under `config/boot/` next to the launcher executable, and take the
     * file name as their only argument. A manifest opts in with the
     * "boot-profiles" feature; every `.ini` becomes a selectable launch target
     * that runs the manifest's default entrypoint with that file as the argument.
     * The feature works for the prefix launcher and for post-install scripts, so
     * Ashita can live next to Windower inside the same prefix.
     */
    public const string FEATURE_BOOT_PROFILES = "boot-profiles";
    public const string BOOT_PROFILE_ID_PREFIX = "boot-profile:";
    public const string BOOT_PROFILE_SUBDIR = "config/boot";

    public string boot_profile_entry_id (string ini_name) {
        return BOOT_PROFILE_ID_PREFIX + Uri.escape_string (ini_name, null, true);
    }

    public string? boot_profile_name_from_entry_id (string entrypoint_id) {
        string instance_id;
        string local_id;
        var scoped = Models.PrefixAction.parse_script_id (entrypoint_id, out instance_id, out local_id);
        var id = scoped ? local_id : entrypoint_id;
        if (!id.has_prefix (BOOT_PROFILE_ID_PREFIX)) return null;
        var suffix = id.substring (BOOT_PROFILE_ID_PREFIX.length);
        if (suffix == "") return null;
        return Uri.unescape_string (suffix);
    }

    public string boot_profile_display_label (string ini_name) {
        var label = ini_name;
        if (label.down ().has_suffix (".ini")) label = label.substring (0, label.length - 4);
        return label.strip () == "" ? _("Default") : label;
    }

    /* The manifest entrypoint that hosts a boot-profile entry id, plus the ini file name. */
    public bool resolve_boot_profile (
        ManifestContext ctx,
        string entrypoint_id,
        out Models.Entrypoint? host,
        out string ini_name
    ) {
        host = null;
        ini_name = "";
        var name = boot_profile_name_from_entry_id (entrypoint_id);
        if (name == null) return false;

        string instance_id;
        string local_id;
        if (!Models.PrefixAction.parse_script_id (entrypoint_id, out instance_id, out local_id)) {
            if (ctx.launcher == null || !ctx.launcher.supports_feature (FEATURE_BOOT_PROFILES)) return false;
            host = default_entrypoint (ctx.launcher.entrypoints);
        } else {
            foreach (var loaded in ctx.post_installs) {
                if (loaded.metadata.id != instance_id) continue;
                if (!loaded.spec.supports_feature (FEATURE_BOOT_PROFILES)) continue;
                host = default_entrypoint (loaded.spec.entrypoints);
                break;
            }
        }
        if (host == null) return false;
        ini_name = name;
        return true;
    }

    public Gee.ArrayList<Models.Entrypoint> list_boot_profile_entrypoints (ManifestContext ctx) {
        var list = new Gee.ArrayList<Models.Entrypoint> ();
        if (ctx.launcher != null && ctx.launcher.supports_feature (FEATURE_BOOT_PROFILES)) {
            add_boot_profile_entries (list, ctx, ctx.launcher.entrypoints, "", ctx.launcher.icon);
        }
        foreach (var loaded in ctx.post_installs) {
            if (!loaded.spec.supports_feature (FEATURE_BOOT_PROFILES)) continue;
            add_boot_profile_entries (list, ctx, loaded.spec.entrypoints, loaded.metadata.id, loaded.spec.icon);
        }
        return list;
    }

    private void add_boot_profile_entries (
        Gee.ArrayList<Models.Entrypoint> list,
        ManifestContext ctx,
        Gee.ArrayList<Models.Entrypoint> entrypoints,
        string script_instance_id,
        string icon
    ) {
        var host = default_entrypoint (entrypoints);
        if (host == null) return;
        var dir = entrypoint_dir_from_context (ctx, host);
        if (dir == "") return;

        foreach (var ini_name in list_boot_profile_files (Path.build_filename (dir, BOOT_PROFILE_SUBDIR))) {
            var ep = new Models.Entrypoint ();
            var local_id = boot_profile_entry_id (ini_name);
            ep.id = script_instance_id != ""
                ? Models.PrefixAction.compose_id (
                    Models.PrefixActionProvider.POST_INSTALL_SCRIPT, script_instance_id, local_id
                )
                : local_id;
            ep.name = ini_name;
            ep.label = boot_profile_display_label (ini_name);
            ep.icon = icon;
            ep.exe = host.exe;
            ep.args.add (ini_name);
            list.add (ep);
        }
    }

    private Gee.ArrayList<string> list_boot_profile_files (string boot_dir) {
        var names = new Gee.ArrayList<string> ();
        try {
            var d = Dir.open (boot_dir);
            string? child;
            while ((child = d.read_name ()) != null) {
                if (!child.down ().has_suffix (".ini")) continue;
                if (!FileUtils.test (Path.build_filename (boot_dir, child), FileTest.IS_REGULAR)) continue;
                names.add (child);
            }
        } catch (FileError e) {
            return names;
        }
        names.sort ((a, b) => strcmp (a.down (), b.down ()));
        return names;
    }

    private Models.Entrypoint build_launcher_profile_entry (string profile_name) {
        var ep = new Models.Entrypoint ();
        ep.id = launcher_profile_entry_id (profile_name);
        ep.name = profile_name;
        ep.label = launcher_profile_display_label (profile_name);
        ep.exe = "";
        return ep;
    }

    private Gee.ArrayList<string> parse_profile_names_from_xml (string xml_text) {
        var names = new Gee.ArrayList<string> ();
        var seen = new Gee.HashSet<string> ();
        try {
            var r = new Regex (
                "<profile\\b[^>]*\\bname\\s*=\\s*(?:\"([^\"]*)\"|'([^']*)')",
                RegexCompileFlags.CASELESS | RegexCompileFlags.DOTALL
            );
            MatchInfo mi;
            if (r.match (xml_text, 0, out mi)) {
                do {
                    var n = mi.fetch (1) ?? "";
                    if (n == "") n = mi.fetch (2) ?? "";
                    if (seen.add (n)) names.add (n);
                } while (mi.next ());
            }
        } catch (Error e) {
            warning ("Launcher profile parse: %s", e.message);
        }
        return names;
    }
}
