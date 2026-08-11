// S14 Part 28 — mirrors the mobile app's ConfigurationErrorApp
// (apps/mobile/lib/core/config/configuration_error_app.dart), shown
// instead of the real app when validateApiConfig rejects the running
// build. Deliberately standalone: the real app's providers/API client
// should never even construct against a configuration this screen has
// already judged unsafe to talk to.
export function ConfigurationErrorScreen({ violations }: { violations: string[] }) {
  return (
    <div
      role="alert"
      style={{
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        background: '#111',
        color: '#fff',
        padding: '24px',
      }}
    >
      <div style={{ maxWidth: 560 }}>
        <h1 style={{ margin: 0, fontSize: 22 }}>Configuration error</h1>
        <p style={{ color: '#ccc', marginTop: 8 }}>This build cannot start safely.</p>
        <ul style={{ marginTop: 24, paddingLeft: 20 }}>
          {violations.map((violation) => (
            <li key={violation} style={{ marginBottom: 12 }}>
              {violation}
            </li>
          ))}
        </ul>
      </div>
    </div>
  );
}
