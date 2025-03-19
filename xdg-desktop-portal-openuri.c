/*
 * Minimal xdg-desktop-portal frontend with OpenURI support
 * SPDX-License-Identifier: MIT
 * ... (MIT License text omitted for brevity) ...
 */

#include <gio/gio.h>
#include <gio/gunixfdlist.h>
#include <glib.h>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>

#define BUS_NAME "org.freedesktop.portal.Desktop"
#define OBJECT_PATH "/org/freedesktop/portal/desktop"
#define INTERFACE "org.freedesktop.portal.OpenURI"

// Version defined at build time, defaults if not set
#ifndef VERSION
#define VERSION "1.0.0"
#endif

static GMainLoop *loop = NULL;

static void
handle_method_call(GDBusConnection *connection,
                   const gchar *sender,
                   const gchar *object_path,
                   const gchar *interface_name,
                   const gchar *method_name,
                   GVariant *parameters,
                   GDBusMethodInvocation *invocation,
                   gpointer user_data)
{
    if (g_strcmp0(method_name, "OpenURI") == 0)
    {
        const gchar *parent_window;
        const gchar *uri;
        GVariant *options;

        g_variant_get(parameters, "(ss@a{sv})", &parent_window, &uri, &options);
        g_print("OpenURI called: parent_window=%s, uri=%s\n", parent_window, uri);

        pid_t pid = fork();
        if (pid == 0)
        {
            unsetenv("LD_LIBRARY_PATH");
            const char *display = getenv("DISPLAY");
            if (display == NULL || display[0] == '\0')
            {
                display = ":0";
            }
            setenv("DISPLAY", display, 1);
            execl("/usr/bin/xdg-open", "xdg-open", uri, (char *)NULL);
            perror("execl failed");
            exit(1);
        }
        else if (pid > 0)
        {
            g_dbus_method_invocation_return_value(invocation,
                                                  g_variant_new("(o)", "/org/freedesktop/portal/desktop/request/1"));
        }
        else
        {
            g_dbus_method_invocation_return_dbus_error(invocation,
                                                       "org.freedesktop.portal.Error.Failed", "Failed to fork");
        }

        g_variant_unref(options);
    }
    else if (g_strcmp0(method_name, "OpenFile") == 0)
    {
        g_dbus_method_invocation_return_value(invocation,
                                              g_variant_new("(o)", "/org/freedesktop/portal/desktop/request/1"));
    }
}

static const GDBusInterfaceVTable interface_vtable = {
    .method_call = handle_method_call,
    .get_property = NULL,
    .set_property = NULL};

static void
on_bus_acquired(GDBusConnection *connection,
                const gchar *name,
                gpointer user_data)
{
    GError *error = NULL;
    const gchar *interface_xml =
        "<node>"
        "  <interface name='" INTERFACE "'>"
        "    <method name='OpenURI'>"
        "      <arg type='s' name='parent_window' direction='in'/>"
        "      <arg type='s' name='uri' direction='in'/>"
        "      <arg type='a{sv}' name='options' direction='in'/>"
        "      <arg type='o' name='handle' direction='out'/>"
        "    </method>"
        "    <method name='OpenFile'>"
        "      <arg type='s' name='parent_window' direction='in'/>"
        "      <arg type='h' name='fd' direction='in'/>"
        "      <arg type='a{sv}' name='options' direction='in'/>"
        "      <arg type='o' name='handle' direction='out'/>"
        "    </method>"
        "  </interface>"
        "</node>";

    guint registration_id = g_dbus_connection_register_object(connection,
                                                              OBJECT_PATH,
                                                              g_dbus_node_info_new_for_xml(interface_xml, NULL)->interfaces[0],
                                                              &interface_vtable,
                                                              NULL, NULL, &error);
    if (error)
    {
        g_printerr("Failed to register object: %s\n", error->message);
        g_clear_error(&error);
        g_main_loop_quit(loop);
    }
    else
    {
        g_print("Registered OpenURI interface at %s\n", OBJECT_PATH);
    }
}

static void
on_name_acquired(GDBusConnection *connection,
                 const gchar *name,
                 gpointer user_data)
{
    g_print("Acquired bus name: %s\n", name);
}

static void
on_name_lost(GDBusConnection *connection,
             const gchar *name,
             gpointer user_data)
{
    g_printerr("Lost bus name: %s\n", name);
    g_main_loop_quit(loop);
}

int main(int argc, char *argv[])
{
    if (argc > 1 && strcmp(argv[1], "--version") == 0)
    {
        printf("xdg-desktop-portal-openuri version %s\n", VERSION);
        return 0;
    }

    loop = g_main_loop_new(NULL, FALSE);

    guint owner_id = g_bus_own_name(G_BUS_TYPE_SESSION,
                                    BUS_NAME,
                                    G_BUS_NAME_OWNER_FLAGS_REPLACE,
                                    on_bus_acquired,
                                    on_name_acquired,
                                    on_name_lost,
                                    NULL, NULL);

    g_main_loop_run(loop);

    g_bus_unown_name(owner_id);
    g_main_loop_unref(loop);

    return 0;
}