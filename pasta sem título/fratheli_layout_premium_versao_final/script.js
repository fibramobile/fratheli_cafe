const API_BASE = "https://frathelicafe.com.br/api";
const PAYMENT_BASE = "https://frathelicafe.com.br/pagamento_order.html?orderId=";
const VISIT_COUNTER_URL = "https://frathelicafe.com.br/contador_visitas.php";
const FREIGHT_QUOTE_URL = "https://frathelicafe.com.br/cotacao_frete.php";
const COFFEE_SALE_SYNC_URL = "https://southamerica-east1-coffee-sale-fibramobile.cloudfunctions.net/createStorefrontSale";

const STORAGE = {
  token: "fratheli_auth_token",
  user: "fratheli_auth_user",
  cart: "fratheli_cart",
  pendingSyncs: "fratheli_pending_order_syncs"
};

const productData = {
  bugia: {
    sku: "BUGIA-250",
    title: "Bugia",
    description: "Microlote de café especial produzido em pequena escala e processado no pós-colheita com mel de Bugia, a Uruçu Amarela.",
    name: "Bugia 250 g",
    price: 39,
    facts: { Pontuação: "86 pontos", Processo: "Honey + mel nativo", Abelha: "Uruçu Amarela", Origem: "Alfredo Chaves · ES", Altitude: "700 m", Perfil: "Chocolate e damasco" }
  },
  tiuba: {
    sku: "TIUBA-250",
    title: "Tiúba",
    description: "Edição autoral com doçura marcante, desenvolvida a partir do processo honey e do mel da Uruçu Cinzenta.",
    name: "Tiúba 250 g",
    price: 39,
    facts: { Pontuação: "86 pontos", Processo: "Honey + mel nativo", Abelha: "Uruçu Cinzenta", Origem: "Alfredo Chaves · ES", Altitude: "700 m", Perfil: "Chocolate e frutas amarelas" }
  },
  aracari: {
    sku: "ARACARI-250",
    title: "Araçari",
    description: "Café especial das Montanhas Capixabas com processo natural e perfil equilibrado para diferentes métodos de preparo.",
    name: "Araçari 250 g",
    price: 37,
    facts: { Pontuação: "84 pontos", Processo: "Natural", Categoria: "Especial", Origem: "Alfredo Chaves · ES", Altitude: "700 m", Perfil: "Caramelo e castanhas" }
  }
};

const catalog = Object.values(productData);
const state = {
  items: [],
  token: localStorage.getItem(STORAGE.token),
  user: readJson(localStorage.getItem(STORAGE.user)),
  shipping: { mode: "calculated", cep: "", quotedCep: "", value: null, service: "", deadline: "", options: [] },
  resumeCheckout: false
};

const currency = value => new Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL" }).format(value);
const drawer = document.querySelector(".cart-drawer");
const backdrop = document.querySelector(".drawer-backdrop");
const toast = document.querySelector(".toast");
const productDialog = document.querySelector(".product-dialog");
const authDialog = document.querySelector(".auth-dialog");
const accountDialog = document.querySelector(".account-dialog");
const ordersDialog = document.querySelector(".orders-dialog");
const checkoutDialog = document.querySelector(".checkout-dialog");
let dialogProduct = null;

function readJson(raw, fallback = null) {
  try {
    return raw ? JSON.parse(raw) : fallback;
  } catch (_) {
    return fallback;
  }
}

function escapeHtml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function showToast(message, duration = 2600) {
  toast.textContent = message;
  toast.classList.add("show");
  window.setTimeout(() => toast.classList.remove("show"), duration);
}

function openDrawer() {
  drawer.classList.add("open");
  drawer.setAttribute("aria-hidden", "false");
  backdrop.hidden = false;
  document.body.classList.add("no-scroll");
  drawer.querySelector(".drawer-close").focus();
}

function closeDrawer() {
  drawer.classList.remove("open");
  drawer.setAttribute("aria-hidden", "true");
  backdrop.hidden = true;
  document.body.classList.remove("no-scroll");
}

function persistCart() {
  localStorage.setItem(STORAGE.cart, JSON.stringify(state.items));
}

function restoreCart() {
  const stored = readJson(localStorage.getItem(STORAGE.cart), []);
  if (!Array.isArray(stored)) return;
  state.items = stored.flatMap(item => {
    const product = catalog.find(entry => entry.sku === item.sku);
    const quantity = Math.max(1, Math.min(99, Number(item.quantity) || 1));
    const grind = item.grind === "Moído" ? "Moído" : "Grão";
    return product ? [{ sku: product.sku, name: product.name, price: product.price, grind, quantity }] : [];
  });
}

function addItem(sku, name, price, grind = "Grão") {
  const found = state.items.find(item => item.sku === sku && item.grind === grind);
  if (found) found.quantity += 1;
  else state.items.push({ sku, name, price, grind, quantity: 1 });
  invalidateFreightQuote();
  persistCart();
  renderCart();
  showToast(`${name} (${grind.toLowerCase()}) adicionado à sacola.`);
}

function changeQuantity(index, delta) {
  const item = state.items[index];
  if (!item) return;
  item.quantity += delta;
  if (item.quantity <= 0) state.items.splice(index, 1);
  invalidateFreightQuote();
  persistCart();
  renderCart();
}

function cartSubtotal() {
  return state.items.reduce((sum, item) => sum + item.price * item.quantity, 0);
}

function effectiveFreight() {
  return state.shipping.mode === "calculated" && Number.isFinite(state.shipping.value)
    ? state.shipping.value
    : 0;
}

function orderTotal() {
  return cartSubtotal() + effectiveFreight();
}

function invalidateFreightQuote() {
  state.shipping.quotedCep = "";
  state.shipping.value = null;
  state.shipping.service = "";
  state.shipping.deadline = "";
  state.shipping.options = [];
}

function selectFreight(index) {
  const option = state.shipping.options[index];
  if (!option) return;
  state.shipping.value = option.value;
  state.shipping.service = option.service;
  state.shipping.deadline = option.deadline;
  renderCart();
  showToast(`Frete selecionado: ${option.service} — ${currency(option.value)}`);
}

function renderFreight() {
  const calculator = document.querySelector(".freight-calculator");
  const results = document.querySelector(".freight-results");
  const freightValue = document.querySelector(".cart-freight");
  const freightMeta = document.querySelector(".freight-selected-meta");
  const calculated = state.shipping.mode === "calculated";

  document.querySelectorAll('[name="freight-mode"]').forEach(input => {
    input.checked = input.value === state.shipping.mode;
  });
  calculator.hidden = !calculated;

  if (!calculated) {
    freightValue.textContent = "A combinar";
    freightMeta.textContent = "Definido diretamente com a Frathéli";
    results.innerHTML = "";
    return;
  }

  freightValue.textContent = Number.isFinite(state.shipping.value) ? currency(state.shipping.value) : "A calcular";
  freightMeta.textContent = state.shipping.service
    ? `${state.shipping.service}${state.shipping.deadline ? ` · ${state.shipping.deadline}` : ""}`
    : "";
  results.innerHTML = state.shipping.options.map((option, index) => `
    <button class="freight-option${option.service === state.shipping.service && option.value === state.shipping.value ? " selected" : ""}" type="button" data-index="${index}">
      <strong>${escapeHtml(option.service)}</strong>
      <span>${escapeHtml(option.deadline || "Prazo a confirmar")}</span>
      <b>${currency(option.value)}</b>
    </button>`).join("");
  results.querySelectorAll(".freight-option").forEach(button => {
    button.addEventListener("click", () => selectFreight(Number(button.dataset.index)));
  });
}

function renderCart() {
  const itemsElement = document.querySelector(".cart-items");
  const count = state.items.reduce((sum, item) => sum + item.quantity, 0);
  document.querySelector(".cart-count").textContent = count;
  document.querySelector(".cart-subtotal").textContent = currency(cartSubtotal());
  document.querySelector(".cart-total").textContent = currency(orderTotal());
  document.querySelector(".checkout-subtotal-value").textContent = currency(cartSubtotal());
  document.querySelector(".checkout-freight-value").textContent = state.shipping.mode === "calculated" && Number.isFinite(state.shipping.value) ? currency(state.shipping.value) : "A combinar";
  document.querySelector(".checkout-total-value").textContent = currency(orderTotal());
  renderFreight();

  if (!state.items.length) {
    itemsElement.innerHTML = '<p class="empty-cart">Sua sacola está vazia.</p>';
    return;
  }

  itemsElement.innerHTML = state.items.map((item, index) => `
    <div class="cart-item">
      <p><strong>${escapeHtml(item.name)}</strong><small>${escapeHtml(item.grind)} · ${currency(item.price)} cada</small></p>
      <div class="quantity-actions" aria-label="Quantidade de ${escapeHtml(item.name)}">
        <button type="button" data-index="${index}" data-delta="-1" aria-label="Diminuir quantidade">−</button>
        <span>${item.quantity}</span>
        <button type="button" data-index="${index}" data-delta="1" aria-label="Aumentar quantidade">+</button>
      </div>
    </div>`).join("");

  itemsElement.querySelectorAll(".quantity-actions button").forEach(button => {
    button.addEventListener("click", () => changeQuantity(Number(button.dataset.index), Number(button.dataset.delta)));
  });
}

function setAuth(auth) {
  state.token = auth?.token || null;
  state.user = auth?.user || null;
  if (state.token && state.user) {
    localStorage.setItem(STORAGE.token, state.token);
    localStorage.setItem(STORAGE.user, JSON.stringify(state.user));
  } else {
    localStorage.removeItem(STORAGE.token);
    localStorage.removeItem(STORAGE.user);
  }
  renderAuth();
}

function renderAuth() {
  const trigger = document.querySelector(".account-trigger");
  const label = document.querySelector(".account-label");
  const icon = document.querySelector(".account-icon");
  if (state.token && state.user) {
    const firstName = String(state.user.name || "Cliente").trim().split(/\s+/)[0];
    label.textContent = firstName ? `Olá, ${firstName}` : "Minha conta";
    icon.textContent = firstName ? firstName.charAt(0).toUpperCase() : "F";
    trigger.setAttribute("aria-label", "Abrir minha conta");
  } else {
    label.textContent = "Entrar";
    icon.textContent = "●";
    trigger.setAttribute("aria-label", "Entrar na conta");
  }
}

async function requestJson(url, options = {}) {
  const response = await fetch(url, {
    mode: "cors",
    cache: "no-store",
    ...options,
    headers: { Accept: "application/json", ...(options.headers || {}) }
  });
  const body = readJson(await response.text(), {});
  if (!response.ok) {
    const error = new Error(String(body.error || "Não foi possível concluir a operação."));
    error.status = response.status;
    throw error;
  }
  return body;
}

async function hydrateAuth() {
  renderAuth();
  if (!state.token) return;
  try {
    const body = await requestJson(`${API_BASE}/account/me.php`, {
      headers: { Authorization: `Bearer ${state.token}` }
    });
    if (body.user) setAuth({ token: state.token, user: { ...state.user, ...body.user } });
    retryPendingSyncs();
  } catch (error) {
    if (error.status === 401 || error.status === 403) setAuth(null);
  }
}

function switchAuthView(view) {
  const login = view === "login";
  authDialog.querySelector(".login-form").hidden = !login;
  authDialog.querySelector(".register-form").hidden = login;
  authDialog.querySelector("#auth-title").textContent = login ? "Entrar" : "Criar conta";
  authDialog.querySelectorAll(".auth-tab").forEach(tab => {
    const active = tab.dataset.authView === view;
    tab.classList.toggle("active", active);
    tab.setAttribute("aria-selected", String(active));
  });
}

function openAuth(view = "login", message = "Use a mesma conta que você já possui no site da Frathéli.") {
  switchAuthView(view);
  authDialog.querySelector(".auth-message").textContent = message;
  authDialog.querySelectorAll(".form-error").forEach(item => item.textContent = "");
  authDialog.showModal();
}

function setSubmitState(button, loading, defaultText) {
  button.disabled = loading;
  button.textContent = loading ? "Aguarde…" : defaultText;
}

document.querySelector(".login-form").addEventListener("submit", async event => {
  event.preventDefault();
  const form = event.currentTarget;
  const errorElement = form.querySelector(".login-error");
  const button = form.querySelector(".auth-submit");
  errorElement.textContent = "";
  if (!form.reportValidity()) return;
  setSubmitState(button, true, "Entrar");
  try {
    const data = Object.fromEntries(new FormData(form));
    const body = await requestJson(`${API_BASE}/auth/login.php`, {
      method: "POST",
      headers: { "Content-Type": "application/json; charset=utf-8" },
      body: JSON.stringify({ email: data.email.trim(), password: data.password })
    });
    if (!body.token || !body.user) throw new Error("Resposta inválida do servidor.");
    setAuth({ token: body.token, user: body.user });
    authDialog.close();
    form.reset();
    showToast("Login realizado com sucesso.");
    retryPendingSyncs();
    if (state.resumeCheckout) {
      state.resumeCheckout = false;
      openCheckout();
    }
  } catch (error) {
    errorElement.textContent = error.message;
  } finally {
    setSubmitState(button, false, "Entrar");
  }
});

document.querySelector(".register-form").addEventListener("submit", async event => {
  event.preventDefault();
  const form = event.currentTarget;
  const errorElement = form.querySelector(".register-error");
  const button = form.querySelector(".auth-submit");
  errorElement.textContent = "";
  if (!form.reportValidity()) return;
  setSubmitState(button, true, "Criar minha conta");
  try {
    const data = Object.fromEntries(new FormData(form));
    const body = await requestJson(`${API_BASE}/auth/register.php`, {
      method: "POST",
      headers: { "Content-Type": "application/json; charset=utf-8" },
      body: JSON.stringify({ name: data.name.trim(), email: data.email.trim(), whatsapp: data.whatsapp.trim(), password: data.password })
    });
    if (!body.token || !body.user) throw new Error("Resposta inválida do servidor.");
    setAuth({ token: body.token, user: body.user });
    authDialog.close();
    form.reset();
    showToast("Conta criada. Você já está conectado.");
    if (state.resumeCheckout) {
      state.resumeCheckout = false;
      openCheckout();
    }
  } catch (error) {
    errorElement.textContent = error.message;
  } finally {
    setSubmitState(button, false, "Criar minha conta");
  }
});

function showAccount() {
  const name = String(state.user?.name || "Cliente Frathéli");
  accountDialog.querySelector(".account-name").textContent = name;
  accountDialog.querySelector(".account-email").textContent = String(state.user?.email || "");
  accountDialog.querySelector(".account-avatar").textContent = name.trim().charAt(0).toUpperCase() || "F";
  accountDialog.showModal();
}

function formatOrderDate(raw) {
  if (!raw) return "Data não informada";
  const date = new Date(String(raw).replace(" ", "T"));
  if (Number.isNaN(date.getTime())) return String(raw);
  return new Intl.DateTimeFormat("pt-BR", {
    day: "2-digit", month: "2-digit", year: "numeric", hour: "2-digit", minute: "2-digit"
  }).format(date).replace(",", " ·");
}

function numberFrom(value) {
  if (typeof value === "number") return Number.isFinite(value) ? value : 0;
  const normalized = String(value ?? "0").trim().replace(/\.(?=\d{3}(?:\D|$))/g, "").replace(",", ".");
  const parsed = Number(normalized);
  return Number.isFinite(parsed) ? parsed : 0;
}

function pick(object, keys, fallback = "") {
  for (const key of keys) {
    const value = object?.[key];
    if (value !== undefined && value !== null && String(value).trim() !== "") return value;
  }
  return fallback;
}

function orderStatus(raw, kind) {
  const status = String(raw || "").toUpperCase().trim();
  if (status.includes("CANCEL") || status.includes("REJEIT")) return { label: "Cancelado", className: "status-cancelled" };
  if (kind === "payment" && (status.includes("PAGO") || status.includes("APROV"))) return { label: "Pago", className: "status-paid" };
  if (kind === "shipping" && (status.includes("ENTREG") || status.includes("CONCLU"))) return { label: "Entregue", className: "status-delivered" };
  if (kind === "shipping" && (status.includes("ENVI") || status.includes("POST") || status.includes("TRANSP"))) return { label: "Enviado", className: "status-shipped" };
  if (kind === "shipping" && (status.includes("PREPAR") || status.includes("SEPAR"))) return { label: "Preparando pedido", className: "status-pending" };
  return { label: kind === "payment" ? "Aguardando pagamento" : "Aguardando pagamento", className: "status-pending" };
}

function orderCode(order) {
  return String(pick(order, ["order_code", "id", "orderId", "order_id"], "Pedido"));
}

function orderPaymentStatus(order) {
  return orderStatus(pick(order, ["paymentStatus", "payment_status"]), "payment");
}

function orderShippingStatus(order) {
  return orderStatus(pick(order, ["shippingStatus", "shipping_status"]), "shipping");
}

function canPayOrder(order) {
  const raw = String(pick(order, ["paymentStatus", "payment_status"])).toUpperCase();
  return !raw.includes("PAGO") && !raw.includes("APROV") && !raw.includes("CANCEL") && !raw.includes("REJEIT");
}

function statusMarkup(title, status) {
  return `<div class="order-status ${status.className}"><span><small>${escapeHtml(title)}</small><strong>${escapeHtml(status.label)}</strong></span></div>`;
}

function orderCardMarkup(order) {
  const code = orderCode(order);
  const total = numberFrom(pick(order, ["total"]));
  const createdAt = pick(order, ["created_at", "createdAt"]);
  const payment = orderPaymentStatus(order);
  const shipping = orderShippingStatus(order);
  return `
    <article class="order-card">
      <div class="order-card-top">
        <div><h3 class="order-number">Pedido #${escapeHtml(code)}</h3><time class="order-date">${escapeHtml(formatOrderDate(createdAt))}</time></div>
        <strong class="order-total">${currency(total)}</strong>
      </div>
      <div class="order-statuses">
        ${statusMarkup("Pagamento", payment)}
        ${statusMarkup("Entrega", shipping)}
      </div>
      <div class="order-actions">
        <button class="button button-outline order-details-button" type="button" data-order-id="${escapeHtml(code)}">Ver pedido</button>
        ${canPayOrder(order) ? `<a class="button button-primary" href="${PAYMENT_BASE}${encodeURIComponent(code)}">Pagar com Pix</a>` : ""}
      </div>
    </article>`;
}

function renderOrdersFeedback(title, message, action = "") {
  ordersDialog.querySelector(".orders-content").innerHTML = `
    <div class="orders-feedback"><div><strong>${escapeHtml(title)}</strong><span>${escapeHtml(message)}</span>${action}</div></div>`;
}

async function loadOrders() {
  if (!state.token) {
    ordersDialog.close();
    openAuth("login", "Entre para visualizar seus pedidos e acompanhar o status.");
    return;
  }
  renderOrdersFeedback("Buscando seus pedidos…", "Só um instante.");
  try {
    const body = await requestJson(`${API_BASE}/orders/list.php`, {
      headers: { Authorization: `Bearer ${state.token}` }
    });
    const orders = Array.isArray(body.orders) ? body.orders : [];
    if (!orders.length) {
      renderOrdersFeedback("Nenhum pedido ainda", "Quando você fizer uma compra, ela aparecerá aqui com o status atualizado.", '<button class="button button-primary orders-shop-button" type="button">Escolher um café</button>');
      return;
    }
    ordersDialog.querySelector(".orders-content").innerHTML = `<div class="orders-list">${orders.map(orderCardMarkup).join("")}</div>`;
  } catch (error) {
    if (error.status === 401 || error.status === 403) {
      setAuth(null);
      ordersDialog.close();
      openAuth("login", "Sua sessão terminou. Entre novamente para visualizar seus pedidos.");
      return;
    }
    renderOrdersFeedback("Não foi possível carregar", error.message, '<button class="button button-primary orders-retry-button" type="button">Tentar novamente</button>');
  }
}

function orderItemsMarkup(items) {
  if (!items.length) return '<li><span>Itens não informados</span></li>';
  return items.map(item => {
    const quantity = Number(pick(item, ["qty", "quantity"], 1)) || 1;
    const name = String(pick(item, ["name", "product_name"], "Café Frathéli"));
    const grind = String(pick(item, ["grind"], ""));
    const lineTotal = numberFrom(pick(item, ["lineTotal", "line_total", "price", "unitPrice", "unit_price"]));
    return `<li><span><strong>${quantity}× ${escapeHtml(name)}</strong>${grind ? `<small>${escapeHtml(grind)}</small>` : ""}</span><strong>${currency(lineTotal)}</strong></li>`;
  }).join("");
}

function renderOrderDetails(body, fallbackCode) {
  const order = body.order && typeof body.order === "object" ? body.order : body;
  const items = Array.isArray(body.items) ? body.items : (Array.isArray(order.items) ? order.items : []);
  const code = orderCode(order) === "Pedido" ? fallbackCode : orderCode(order);
  const payment = orderPaymentStatus(order);
  const shipping = orderShippingStatus(order);
  const subtotal = numberFrom(pick(order, ["subtotal"]));
  const freight = numberFrom(pick(order, ["shipping", "freight"]));
  const total = numberFrom(pick(order, ["total"]));
  const service = String(pick(order, ["shippingService", "shipping_service"]));
  const deadline = String(pick(order, ["shippingDeadline", "shipping_deadline"]));
  const createdAt = pick(order, ["created_at", "createdAt"]);
  ordersDialog.querySelector(".orders-content").innerHTML = `
    <div class="order-details-head">
      <div><time class="order-date">${escapeHtml(formatOrderDate(createdAt))}</time><h3>Pedido #${escapeHtml(code)}</h3></div>
      <button class="orders-back" type="button">← Voltar aos pedidos</button>
    </div>
    <div class="order-details-grid">
      <section class="order-panel">
        <h4>Acompanhamento</h4>
        <div class="order-statuses">${statusMarkup("Pagamento", payment)}${statusMarkup("Entrega", shipping)}</div>
        ${service || deadline ? `<p class="order-shipping-copy"><strong>Frete:</strong> ${escapeHtml(service || "Entrega")}${deadline ? ` · ${escapeHtml(deadline)}` : ""}</p>` : ""}
      </section>
      <section class="order-panel order-values">
        <h4>Resumo</h4>
        <div><span>Subtotal</span><strong>${currency(subtotal)}</strong></div>
        <div><span>Frete</span><strong>${currency(freight)}</strong></div>
        <div class="order-values-total"><span>Total</span><strong>${currency(total)}</strong></div>
      </section>
      <section class="order-panel order-panel-wide">
        <h4>Itens do pedido</h4>
        <ul class="order-items">${orderItemsMarkup(items)}</ul>
      </section>
    </div>
    ${canPayOrder(order) ? `<div class="order-actions"><a class="button button-primary" href="${PAYMENT_BASE}${encodeURIComponent(code)}">Continuar pagamento com Pix</a></div>` : ""}`;
}

async function loadOrderDetails(code) {
  renderOrdersFeedback("Abrindo o pedido…", "Buscando os detalhes e o status mais recente.");
  try {
    const body = await requestJson(`${API_BASE}/orders/get.php?id=${encodeURIComponent(code)}`, {
      headers: { Authorization: `Bearer ${state.token}` }
    });
    renderOrderDetails(body, code);
  } catch (error) {
    if (error.status === 401 || error.status === 403) {
      setAuth(null);
      ordersDialog.close();
      openAuth("login", "Sua sessão terminou. Entre novamente para visualizar o pedido.");
      return;
    }
    renderOrdersFeedback("Pedido indisponível", error.message, '<button class="button button-outline orders-back" type="button">Voltar aos pedidos</button>');
  }
}

function openOrders() {
  accountDialog.close();
  ordersDialog.showModal();
  loadOrders();
}

async function loadVisitCount() {
  const element = document.querySelector("#visit-count");
  try {
    const body = await requestJson(VISIT_COUNTER_URL);
    if (body.ok !== true || body.total == null) throw new Error("Contador indisponível");
    element.textContent = `${Number(body.total).toLocaleString("pt-BR")} visitas registradas`;
  } catch (_) {
    element.textContent = "";
    document.querySelector(".visit-divider").hidden = true;
  }
}

function formatCep(value) {
  const digits = onlyDigits(value).slice(0, 8);
  return digits.length > 5 ? `${digits.slice(0, 5)}-${digits.slice(5)}` : digits;
}

async function calculateFreight() {
  const input = document.querySelector("#cart-cep");
  const button = document.querySelector(".calculate-freight");
  const errorElement = document.querySelector(".freight-error");
  const cep = onlyDigits(input.value);
  const quantity = state.items.reduce((sum, item) => sum + item.quantity, 0);

  errorElement.textContent = "";
  if (!quantity) {
    errorElement.textContent = "Adicione um café antes de calcular o frete.";
    return;
  }
  if (cep.length !== 8) {
    errorElement.textContent = "Digite um CEP com 8 dígitos.";
    return;
  }

  setSubmitState(button, true, "Calcular");
  try {
    const url = `${FREIGHT_QUOTE_URL}?cep=${encodeURIComponent(cep)}&qtd=${quantity}`;
    const body = await requestJson(url);
    if (body.ok !== true) throw new Error(String(body.erro || "Não foi possível calcular o frete para este CEP."));
    const options = Array.isArray(body.opcoes) ? body.opcoes.flatMap(option => {
      const value = Number(option.valor);
      if (!Number.isFinite(value)) return [];
      return [{ service: String(option.transportadora || "Frete"), value, deadline: String(option.prazo || "") }];
    }) : [];
    if (!options.length) throw new Error("Nenhuma opção de frete foi encontrada para este CEP.");

    state.shipping.mode = "calculated";
    state.shipping.cep = formatCep(cep);
    state.shipping.quotedCep = cep;
    state.shipping.value = null;
    state.shipping.service = "";
    state.shipping.deadline = "";
    state.shipping.options = options;
    input.value = state.shipping.cep;
    renderCart();
    document.querySelector(".freight-results").scrollIntoView({ block: "nearest", behavior: "smooth" });
  } catch (error) {
    invalidateFreightQuote();
    renderCart();
    errorElement.textContent = error.message;
  } finally {
    setSubmitState(button, false, "Calcular");
  }
}

function openCheckout() {
  if (!state.items.length) {
    showToast("Adicione um café antes de continuar.");
    return;
  }
  if (state.shipping.mode === "calculated" && !Number.isFinite(state.shipping.value)) {
    showToast("Calcule o frete e escolha uma opção antes de continuar.", 3200);
    if (!drawer.classList.contains("open")) openDrawer();
    return;
  }
  if (!state.token || !state.user) {
    closeDrawer();
    state.resumeCheckout = true;
    openAuth("login", "Entre com sua conta Frathéli para finalizar o pedido.");
    return;
  }
  const form = document.querySelector(".checkout-form");
  form.querySelector('[name="name"]').value = state.user.name || "";
  form.querySelector('[name="phone"]').value = state.user.whatsapp || state.user.phone || "";
  const cepInput = form.querySelector('[name="cep"]');
  const consent = form.querySelector(".checkout-consent");
  const consentInput = consent.querySelector("input");
  cepInput.value = state.shipping.cep || cepInput.value;
  cepInput.readOnly = state.shipping.mode === "calculated";
  consent.hidden = state.shipping.mode === "calculated";
  consentInput.required = state.shipping.mode !== "calculated";
  consentInput.checked = state.shipping.mode === "calculated";
  document.querySelector(".checkout-intro").textContent = state.shipping.mode === "calculated"
    ? `Entrega selecionada: ${state.shipping.service}${state.shipping.deadline ? ` · ${state.shipping.deadline}` : ""}.`
    : "Confirme seus dados. O frete será combinado diretamente com a Frathéli.";
  form.querySelector(".checkout-error").textContent = "";
  renderCart();
  closeDrawer();
  checkoutDialog.showModal();
}

function onlyDigits(value) {
  return String(value || "").replace(/\D/g, "");
}

function queuePendingSync(orderCode, customer) {
  const pending = readJson(localStorage.getItem(STORAGE.pendingSyncs), []);
  const list = Array.isArray(pending) ? pending.filter(item => item.orderCode !== orderCode) : [];
  list.push({ orderCode, customer });
  localStorage.setItem(STORAGE.pendingSyncs, JSON.stringify(list));
}

async function syncOrder(orderCode, token, customer) {
  const body = await requestJson(COFFEE_SALE_SYNC_URL, {
    method: "POST",
    headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json; charset=utf-8" },
    body: JSON.stringify({ orderId: orderCode, customer })
  });
  if (body.ok !== true) throw new Error(body.error || "Falha ao sincronizar pedido.");
}

async function retryPendingSyncs() {
  if (!state.token) return;
  const pending = readJson(localStorage.getItem(STORAGE.pendingSyncs), []);
  if (!Array.isArray(pending) || !pending.length) return;
  const remaining = [];
  for (const item of pending) {
    try {
      await syncOrder(item.orderCode, state.token, item.customer);
    } catch (_) {
      remaining.push(item);
    }
  }
  if (remaining.length) localStorage.setItem(STORAGE.pendingSyncs, JSON.stringify(remaining));
  else localStorage.removeItem(STORAGE.pendingSyncs);
}

document.querySelector(".checkout-form").addEventListener("submit", async event => {
  event.preventDefault();
  const form = event.currentTarget;
  const errorElement = form.querySelector(".checkout-error");
  const button = form.querySelector(".checkout-submit");
  errorElement.textContent = "";
  if (!form.reportValidity()) return;
  const data = Object.fromEntries(new FormData(form));
  if (state.shipping.mode === "calculated" && !Number.isFinite(state.shipping.value)) {
    errorElement.textContent = "Calcule e selecione uma opção de frete antes de finalizar.";
    return;
  }
  if (onlyDigits(data.cpf).length !== 11) {
    errorElement.textContent = "Informe um CPF com 11 dígitos.";
    return;
  }
  if (onlyDigits(data.cep).length !== 8) {
    errorElement.textContent = "Informe um CEP com 8 dígitos.";
    return;
  }
  if (!state.token) {
    checkoutDialog.close();
    state.resumeCheckout = true;
    openAuth("login", "Sua sessão terminou. Entre novamente para finalizar.");
    return;
  }

  setSubmitState(button, true, "Criar pedido e seguir para o Pix");
  const customer = {
    name: data.name.trim(),
    phone: data.phone.trim(),
    cpf: onlyDigits(data.cpf),
    address: data.address.trim()
  };
  const subtotal = cartSubtotal();
  const shipping = effectiveFreight();
  const calculatedFreight = state.shipping.mode === "calculated";
  const payload = {
    items: state.items.map(item => ({ sku: item.sku, qty: item.quantity, name: item.name, grind: item.grind, unitPrice: item.price, lineTotal: item.price * item.quantity })),
    subtotal,
    shipping,
    total: subtotal + shipping,
    freightMode: calculatedFreight ? "calculated" : "combine",
    shippingService: calculatedFreight ? state.shipping.service : "Frete a combinar",
    shippingDeadline: calculatedFreight ? state.shipping.deadline : "",
    paymentProvider: "PIX_MANUAL",
    paymentStatus: "AGUARDANDO_PAGAMENTO",
    shippingStatus: "AGUARDANDO_PAGAMENTO",
    customer,
    cep: data.cep.trim()
  };

  try {
    const body = await requestJson(`${API_BASE}/orders/create.php`, {
      method: "POST",
      headers: { Authorization: `Bearer ${state.token}`, "Content-Type": "application/json; charset=utf-8" },
      body: JSON.stringify(payload)
    });
    const orderCode = String(body.order?.id || "").trim();
    if (body.ok !== true || !orderCode) throw new Error("O pedido foi recebido sem um código válido.");
    try {
      await syncOrder(orderCode, state.token, customer);
    } catch (_) {
      queuePendingSync(orderCode, customer);
    }
    state.items = [];
    state.shipping = { mode: "calculated", cep: "", quotedCep: "", value: null, service: "", deadline: "", options: [] };
    document.querySelector("#cart-cep").value = "";
    persistCart();
    renderCart();
    showToast("Pedido criado. Abrindo o pagamento…", 3200);
    window.setTimeout(() => window.location.assign(`${PAYMENT_BASE}${encodeURIComponent(orderCode)}`), 700);
  } catch (error) {
    if (error.status === 401 || error.status === 403) {
      setAuth(null);
      checkoutDialog.close();
      state.resumeCheckout = true;
      openAuth("login", "Sua sessão terminou. Entre novamente para finalizar.");
    } else {
      errorElement.textContent = error.message;
    }
  } finally {
    setSubmitState(button, false, "Criar pedido e seguir para o Pix");
  }
});

document.querySelectorAll(".filter").forEach(button => button.addEventListener("click", () => {
  document.querySelectorAll(".filter").forEach(item => item.classList.remove("active"));
  button.classList.add("active");
  const filter = button.dataset.filter;
  document.querySelectorAll(".product-card").forEach(card => {
    card.hidden = filter !== "all" && card.dataset.category !== filter;
  });
}));

document.querySelectorAll(".add-button").forEach(button => button.addEventListener("click", () => {
  const grind = button.closest(".product-info").querySelector(".grind-choice select").value;
  addItem(button.dataset.sku, button.dataset.name, Number(button.dataset.price), grind);
}));

document.querySelectorAll(".details-link").forEach(button => button.addEventListener("click", () => {
  dialogProduct = productData[button.dataset.product];
  productDialog.querySelector(".dialog-title").textContent = dialogProduct.title;
  productDialog.querySelector(".dialog-description").textContent = dialogProduct.description;
  productDialog.querySelector(".dialog-facts").innerHTML = Object.entries(dialogProduct.facts)
    .map(([key, value]) => `<div><dt>${escapeHtml(key)}</dt><dd>${escapeHtml(value)}</dd></div>`).join("");
  productDialog.showModal();
}));

productDialog.querySelector(".dialog-add").addEventListener("click", () => {
  if (dialogProduct) {
    const grind = productDialog.querySelector(".dialog-grind select").value;
    addItem(dialogProduct.sku, dialogProduct.name, dialogProduct.price, grind);
  }
  productDialog.close();
});

document.querySelector(".account-trigger").addEventListener("click", () => state.token && state.user ? showAccount() : openAuth());
document.querySelector(".orders-open-button").addEventListener("click", openOrders);
document.querySelector(".logout-button").addEventListener("click", () => {
  setAuth(null);
  accountDialog.close();
  showToast("Você saiu da sua conta.");
});
document.querySelectorAll(".auth-tab").forEach(button => button.addEventListener("click", () => switchAuthView(button.dataset.authView)));
document.querySelectorAll('[name="freight-mode"]').forEach(input => input.addEventListener("change", () => {
  state.shipping.mode = input.value;
  document.querySelector(".freight-error").textContent = "";
  renderCart();
}));
document.querySelector("#cart-cep").addEventListener("input", event => {
  event.target.value = formatCep(event.target.value);
  state.shipping.cep = event.target.value;
  if (onlyDigits(event.target.value) !== state.shipping.quotedCep) {
    state.shipping.value = null;
    state.shipping.service = "";
    state.shipping.deadline = "";
    state.shipping.options = [];
    renderCart();
  }
});
document.querySelector("#cart-cep").addEventListener("keydown", event => {
  if (event.key === "Enter") {
    event.preventDefault();
    calculateFreight();
  }
});
document.querySelector(".calculate-freight").addEventListener("click", calculateFreight);
document.querySelector(".cart-trigger").addEventListener("click", openDrawer);
document.querySelector(".drawer-close").addEventListener("click", closeDrawer);
document.querySelector(".checkout-action").addEventListener("click", openCheckout);
productDialog.querySelector(".dialog-close").addEventListener("click", () => productDialog.close());
document.querySelector(".auth-close").addEventListener("click", () => authDialog.close());
document.querySelector(".account-close").addEventListener("click", () => accountDialog.close());
document.querySelector(".orders-close").addEventListener("click", () => ordersDialog.close());
document.querySelector(".orders-refresh").addEventListener("click", loadOrders);
ordersDialog.querySelector(".orders-content").addEventListener("click", event => {
  const detailsButton = event.target.closest(".order-details-button");
  if (detailsButton) loadOrderDetails(detailsButton.dataset.orderId);
  if (event.target.closest(".orders-back") || event.target.closest(".orders-retry-button")) loadOrders();
  if (event.target.closest(".orders-shop-button")) {
    ordersDialog.close();
    document.querySelector("#cafes").scrollIntoView({ behavior: "smooth" });
  }
});
document.querySelector(".checkout-close").addEventListener("click", () => checkoutDialog.close());
backdrop.addEventListener("click", closeDrawer);

[productDialog, authDialog, accountDialog, ordersDialog, checkoutDialog].forEach(dialog => {
  dialog.addEventListener("click", event => {
    if (event.target === dialog) dialog.close();
  });
});

const menuToggle = document.querySelector(".menu-toggle");
const nav = document.querySelector(".main-nav");
menuToggle.addEventListener("click", () => {
  const open = nav.classList.toggle("open");
  menuToggle.setAttribute("aria-expanded", String(open));
});
nav.querySelectorAll("a").forEach(link => link.addEventListener("click", () => {
  nav.classList.remove("open");
  menuToggle.setAttribute("aria-expanded", "false");
}));

document.addEventListener("keydown", event => {
  if (event.key === "Escape" && drawer.classList.contains("open")) closeDrawer();
});

restoreCart();
renderCart();
hydrateAuth();
loadVisitCount();
