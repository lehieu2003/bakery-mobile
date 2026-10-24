/// Store settings map (`GET /api/admin/settings` — flat key/values).
typedef AdminSettings = Map<String, String>;

AdminSettings adminSettingsFromJson(Map<String, dynamic> json) => {
  for (final entry in json.entries)
    if (entry.value != null) entry.key: entry.value.toString(),
};
