export const graph = {
  PLAN: {
    deps: [],
    outputs: ["product_spec.md"],
  },
  ARCHITECT: {
    deps: ["PLAN"],
    outputs: ["architecture.md", "api_spec.json"],
  },
  DATABASE: {
    deps: ["ARCHITECT"],
    outputs: ["schema.sql"],
  },
  BACKEND: {
    deps: ["ARCHITECT", "DATABASE"],
    outputs: ["backend.js"],
  },
  FRONTEND: {
    deps: ["ARCHITECT"],
    outputs: ["frontend.jsx"],
  },
  REVIEW: {
    deps: ["BACKEND", "FRONTEND"],
    outputs: ["review.md"],
  },
};
