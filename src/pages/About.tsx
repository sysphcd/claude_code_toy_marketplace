import * as Sentry from "@sentry/react";
import NavigationBar from "@/components/NavigationBar";
import { Button } from "@/components/ui/button";

const AboutContent = () => {
  const triggerError = () => {
    throw new Error("Test error from About page — Sentry is working!");
  };

  const captureManually = () => {
    Sentry.captureException(new Error("Manual capture from About page"));
    alert("Error sent to Sentry! Check your Sentry dashboard.");
  };

  return (
    <div className="min-h-screen bg-background">
      <NavigationBar />

      <main className="px-[var(--page-padding)] py-6">
        <div className="max-w-md mx-auto">
          <h1 className="text-display font-medium text-foreground mb-4">
            About Marketplace
          </h1>
          <p className="text-body text-foreground mb-4">
            Marketplace is your trusted platform for buying and selling authentic pre-owned products.
          </p>
          <p className="text-body text-foreground mb-8">
            We connect sellers with buyers in a safe, secure environment where quality and authenticity are guaranteed.
          </p>

          <div className="border border-border rounded-lg p-4 space-y-3">
            <p className="text-sm font-medium text-foreground">Sentry Integration Test</p>
            <p className="text-xs text-muted-foreground">
              Use these buttons to verify error tracking is working.
            </p>
            <div className="flex gap-3">
              <Button variant="outline" size="sm" onClick={captureManually}>
                Send test event
              </Button>
              <Button variant="destructive" size="sm" onClick={triggerError}>
                Trigger crash
              </Button>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
};

const About = Sentry.withErrorBoundary(AboutContent, {
  fallback: (
    <div className="min-h-screen bg-background flex items-center justify-center">
      <div className="text-center space-y-2">
        <p className="font-medium text-foreground">Something went wrong.</p>
        <p className="text-sm text-muted-foreground">This error has been reported to Sentry.</p>
        <button
          className="text-sm underline text-foreground mt-2"
          onClick={() => window.location.reload()}
        >
          Reload page
        </button>
      </div>
    </div>
  ),
});

export default About;
