import http from "k6/http";
import { check, sleep } from "k6";

export const options = {
  vus: 60,
  duration: "3m",
};

export default function () {
  const response = http.get(`http://${__ENV.LB}/`);
  check(response, { "status es 200": (r) => r.status === 200 });
  sleep(0.05);
}
