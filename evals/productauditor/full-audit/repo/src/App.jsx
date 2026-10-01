import { useEffect, useState } from "react";
import { createRoot } from "react-dom/client";
import { BrowserRouter, Link, NavLink, Route, Routes, useLocation, useNavigate, useParams } from "react-router-dom";
import posthog from "posthog-js";
import { initializePaddle } from "@paddle/paddle-js";
import billingHelp from "../content/help/billing.md?raw";
import { PLANS, PAID_PLAN_KEYS } from "../lib/plans.js";
import PricingTable from "./components/PricingTable.jsx";
import ExportButton from "./components/ExportButton.jsx";

posthog.init(import.meta.env.VITE_POSTHOG_KEY, {
  api_host: import.meta.env.VITE_POSTHOG_HOST,
  person_profiles: "identified_only",
});

async function api(path, { method = "GET", body } = {}) {
  const res = await fetch(path, {
    method,
    headers: { "Content-Type": "application/json" },
    body: body ? JSON.stringify(body) : undefined,
  });
  const data = (res.headers.get("content-type") || "").includes("json") ? await res.json() : null;
  if (!res.ok) {
    const error = new Error(data?.error || "Something went wrong. Try again.");
    error.status = res.status;
    error.data = data;
    throw error;
  }
  return data;
}

function useMe() {
  const [me, setMe] = useState(null);
  async function reload() {
    try {
      const data = await api("/api/me");
      setMe(data);
      posthog.identify(data.user.id);
      posthog.group("workspace", data.workspace.id);
    } catch {
      setMe(false);
    }
  }
  useEffect(() => {
    reload();
  }, []);
  return [me, reload];
}

function AuthForm({ mode, onDone }) {
  const navigate = useNavigate();
  const [error, setError] = useState("");
  async function submit(event) {
    event.preventDefault();
    try {
      await api(`/api/auth/${mode}`, { method: "POST", body: Object.fromEntries(new FormData(event.currentTarget)) });
      await onDone();
      navigate("/projects");
    } catch (err) {
      setError(err.message);
    }
  }
  return (
    <form onSubmit={submit} className="auth">
      <h1>{mode === "signup" ? "Start your 14-day Pro trial" : "Sign in"}</h1>
      <label>
        Email <input name="email" type="email" autoComplete="email" required />
      </label>
      <label>
        Password{" "}
        <input name="password" type="password" minLength={10} required
          autoComplete={mode === "signup" ? "new-password" : "current-password"} />
      </label>
      {mode === "signup" && (
        <label>
          Workspace name <input name="workspaceName" autoComplete="organization" />
        </label>
      )}
      {error && <p role="alert">{error}</p>}
      <button type="submit">{mode === "signup" ? "Create workspace" : "Sign in"}</button>
    </form>
  );
}

// The checkout URL from POST /api/checkout lands here with ?_ptxn=<transaction id>.
function PayPage() {
  const transactionId = new URLSearchParams(useLocation().search).get("_ptxn");
  useEffect(() => {
    initializePaddle({
      environment: import.meta.env.VITE_PADDLE_ENVIRONMENT,
      token: import.meta.env.VITE_PADDLE_CLIENT_TOKEN,
    }).then((paddle) =>
      paddle?.Checkout.open({
        transactionId,
        settings: { successUrl: `${window.location.origin}/api/checkout/success?_ptxn=${transactionId}` },
      }),
    );
  }, [transactionId]);
  return <p>Opening secure checkout...</p>;
}

function Projects() {
  const [projects, setProjects] = useState([]);
  const [error, setError] = useState("");
  useEffect(() => {
    api("/api/projects").then(setProjects);
  }, []);
  async function create(event) {
    event.preventDefault();
    const form = event.currentTarget;
    try {
      const project = await api("/api/projects", { method: "POST", body: { name: form.elements.projectName.value } });
      setProjects([...projects, project]);
      form.reset();
      setError("");
    } catch (err) {
      setError(err.status === 402 ? `Your plan includes ${err.data.limit} projects. Upgrade to add more.` : err.message);
    }
  }
  return (
    <section>
      <h1>Projects</h1>
      <ul>
        {projects.map((project) => (
          <li key={project.id}>
            <Link to={`/projects/${project.id}`}>{project.name}</Link>
          </li>
        ))}
      </ul>
      <form onSubmit={create}>
        <label>
          New project <input name="projectName" required />
        </label>
        <button type="submit">Add project</button>
      </form>
      {error && (
        <p role="alert">
          {error} <Link to="/pricing">See plans</Link>
        </p>
      )}
    </section>
  );
}

function ProjectBoard({ me }) {
  const { id } = useParams();
  const [project, setProject] = useState(null);
  useEffect(() => {
    api(`/api/projects/${id}`).then(setProject);
  }, [id]);
  if (!project) return null;
  async function addCard(event) {
    event.preventDefault();
    const form = event.currentTarget;
    const card = await api(`/api/projects/${id}/cards`, { method: "POST", body: { title: form.elements.title.value } });
    setProject({ ...project, cards: [...project.cards, card] });
    form.reset();
  }
  async function move(card, status) {
    const updated = await api(`/api/cards/${card.id}`, { method: "PATCH", body: { status } });
    setProject({ ...project, cards: project.cards.map((c) => (c.id === card.id ? updated : c)) });
  }
  return (
    <section>
      <h1>{project.name}</h1>
      <ExportButton project={project} features={me.features} />
      {["todo", "doing", "done"].map((status) => (
        <div key={status} className="column">
          <h2>{status === "todo" ? "To do" : status === "doing" ? "Doing" : "Done"}</h2>
          {project.cards
            .filter((card) => card.status === status)
            .map((card) => (
              <article key={card.id}>
                <p>{card.title}</p>
                <select value={card.status} onChange={(e) => move(card, e.target.value)} aria-label="Status">
                  <option value="todo">To do</option>
                  <option value="doing">Doing</option>
                  <option value="done">Done</option>
                </select>
              </article>
            ))}
        </div>
      ))}
      <form onSubmit={addCard}>
        <label>
          New card <input name="title" required />
        </label>
        <button type="submit">Add card</button>
      </form>
    </section>
  );
}

function BillingSettings({ me, reload }) {
  const ws = me.workspace;
  const options = PAID_PLAN_KEYS.flatMap((key) =>
    ["month", "year"].map((interval) => {
      const price = PLANS[key].prices[interval];
      return { priceId: price.id, label: `${PLANS[key].name}, $${price.amount / 100} per ${interval}` };
    }),
  );
  const [priceId, setPriceId] = useState(options[0].priceId);
  const [message, setMessage] = useState("");

  async function run(action) {
    try {
      const result = await action();
      setMessage(result?.message || "");
      await reload();
    } catch (err) {
      setMessage(err.message);
    }
  }
  async function openPaymentPage() {
    const { url } = await api("/api/subscription/payment-method");
    window.location.assign(url);
  }
  function cancel() {
    if (!window.confirm("Cancel your subscription?")) return Promise.resolve();
    return api("/api/subscription/cancel", { method: "POST" });
  }

  return (
    <section>
      <h2>Billing</h2>
      <p>
        Plan: {PLANS[ws.plan]?.name || ws.plan}. Status: {ws.status || "free"}.
        {ws.renewsOn && ` Renews on ${new Date(ws.renewsOn).toLocaleDateString()}.`}
      </p>
      <h3>Change plan</h3>
      {ws.hasSubscription ? (
        <div>
          <select value={priceId} onChange={(e) => setPriceId(e.target.value)} aria-label="New plan">
            {options.map((option) => (
              <option key={option.priceId} value={option.priceId}>
                {option.label}
              </option>
            ))}
          </select>
          <button type="button" onClick={() => run(() => api("/api/subscription/change", { method: "POST", body: { priceId } }))}>
            Change plan
          </button>
          <button type="button" onClick={() => run(openPaymentPage)}>
            Update payment method
          </button>
          <button type="button" onClick={() => run(cancel)}>
            Cancel subscription
          </button>
        </div>
      ) : (
        <Link to="/pricing">See plans</Link>
      )}
      {message && <p role="status">{message}</p>}
    </section>
  );
}

function Settings({ me, reload }) {
  return (
    <div className="settings">
      <nav aria-label="Settings">
        <NavLink to="/settings/workspace">Workspace</NavLink>
        <NavLink to="/settings/billing">Billing</NavLink>
      </nav>
      <Routes>
        <Route
          path="workspace"
          element={
            <section>
              <h2>Workspace</h2>
              <p>Name: {me.workspace.name}</p>
              <p>Owner: {me.user.email}</p>
            </section>
          }
        />
        <Route path="billing" element={<BillingSettings me={me} reload={reload} />} />
      </Routes>
    </div>
  );
}

function FeedbackDialog({ onClose }) {
  const location = useLocation();
  const [state, setState] = useState("idle");
  const [error, setError] = useState("");
  async function submit(event) {
    event.preventDefault();
    setState("sending");
    try {
      await api("/api/feedback", {
        method: "POST",
        body: { message: event.currentTarget.elements.message.value, page: location.pathname },
      });
      setState("sent");
    } catch (err) {
      setError(err.message);
      setState("idle");
    }
  }
  return (
    <dialog open aria-labelledby="feedback-title">
      <h2 id="feedback-title">Send feedback</h2>
      {state === "sent" ? (
        <p>Thanks. We got your message and will reply by email within one business day.</p>
      ) : (
        <form onSubmit={submit}>
          <p>Questions, problems, or ideas? We read every message and reply by email within one business day.</p>
          <label>
            Message <textarea name="message" required minLength={3} maxLength={5000} />
          </label>
          {error && <p role="alert">{error}</p>}
          <button type="submit" disabled={state === "sending"}>
            Send
          </button>
        </form>
      )}
      <button type="button" onClick={onClose}>
        Close
      </button>
    </dialog>
  );
}

function App() {
  const [me, reload] = useMe();
  const [feedbackOpen, setFeedbackOpen] = useState(false);
  if (me === null) return null;
  return (
    <>
      <header>
        <Link to="/">Fieldnote</Link>
        <nav aria-label="Main">
          {me && <NavLink to="/projects">Projects</NavLink>}
          <NavLink to="/pricing">Pricing</NavLink>
          {me && <NavLink to="/settings/billing">Settings</NavLink>}
          <NavLink to="/help/billing">Help</NavLink>
        </nav>
        {me ? (
          <button type="button" onClick={() => setFeedbackOpen(true)}>
            Send feedback
          </button>
        ) : (
          <Link to="/signin">Sign in</Link>
        )}
      </header>
      <main>
        <Routes>
          <Route path="/" element={me ? <Projects /> : <PricingTable />} />
          <Route path="/pricing" element={<PricingTable />} />
          <Route path="/signup" element={<AuthForm mode="signup" onDone={reload} />} />
          <Route path="/signin" element={<AuthForm mode="signin" onDone={reload} />} />
          {me && <Route path="/pay" element={<PayPage />} />}
          {me && <Route path="/projects" element={<Projects />} />}
          {me && <Route path="/projects/:id" element={<ProjectBoard me={me} />} />}
          {me && <Route path="/settings/*" element={<Settings me={me} reload={reload} />} />}
          <Route path="/help/billing" element={<article className="help" style={{ whiteSpace: "pre-wrap" }}>{billingHelp}</article>} />
        </Routes>
      </main>
      {feedbackOpen && <FeedbackDialog onClose={() => setFeedbackOpen(false)} />}
    </>
  );
}

createRoot(document.getElementById("root")).render(
  <BrowserRouter>
    <App />
  </BrowserRouter>,
);
