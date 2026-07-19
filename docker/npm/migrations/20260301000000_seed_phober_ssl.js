import fs from "node:fs";
import { migrate as logger } from "../logger.js";
import internalCertificate from "../internal/certificate.js";
import internalNginx from "../internal/nginx.js";
import certificateModel from "../models/certificate.js";
import proxyHostModel from "../models/proxy_host.js";

const migrateName = "seed_phober_ssl";

const CERT_FILE = "/certs/phober.test.pem";
const KEY_FILE = "/certs/phober.test-key.pem";
const CERT_NICE_NAME = "Phober Local";

const PROXY_HOSTS = [
	{ domain_names: ["phober.test"], forward_host: "website", forward_port: 80 },
	{ domain_names: ["admin.phober.test"], forward_host: "adminpanel", forward_port: 80 },
	{ domain_names: ["api.phober.test"], forward_host: "api-gateway", forward_port: 80 },
	{ domain_names: ["staff.phober.test"], forward_host: "staff-app", forward_port: 5173 },
	{ domain_names: ["bugs.phober.test"], forward_host: "buggregator", forward_port: 8000 },
	{ domain_names: ["logs.phober.test"], forward_host: "dozzle", forward_port: 8080 },
	{ domain_names: ["zipkin.phober.test"], forward_host: "zipkin", forward_port: 9411 },
];

const formatDate = (date) => date.toISOString().slice(0, 19).replace("T", " ");

const up = async (knex) => {
	logger.info(`[${migrateName}] Migrating Up...`);

	const existing = await knex("certificate").where({ nice_name: CERT_NICE_NAME, is_deleted: 0 }).first();
	if (existing) {
		logger.info(`[${migrateName}] Already seeded, skipping.`);
		return;
	}

	const expiresOn = new Date();
	expiresOn.setFullYear(expiresOn.getFullYear() + 2);

	const certificate = await certificateModel.query().insertAndFetch({
		owner_user_id: 1,
		provider: "other",
		nice_name: CERT_NICE_NAME,
		domain_names: ["mkcert"],
		expires_on: formatDate(expiresOn),
		meta: {
			certificate: fs.readFileSync(CERT_FILE, "utf8"),
			certificate_key: fs.readFileSync(KEY_FILE, "utf8"),
		},
	});
	await internalCertificate.writeCustomCert(certificate);
	logger.info(`[${migrateName}] Certificate #${certificate.id} written`);

	for (const host of PROXY_HOSTS) {
		const inserted = await proxyHostModel.query().insertAndFetch({
			owner_user_id: 1,
			domain_names: host.domain_names,
			forward_host: host.forward_host,
			forward_port: host.forward_port,
			forward_scheme: "http",
			certificate_id: certificate.id,
			ssl_forced: 1,
			http2_support: 1,
			allow_websocket_upgrade: 1,
			locations: [],
			meta: {},
		});

		const row = await proxyHostModel.query().findById(inserted.id).withGraphFetched("certificate");

		try {
			await internalNginx.configure(proxyHostModel, "proxy_host", row);
			logger.info(`[${migrateName}] ${host.domain_names.join(", ")} -> ${host.forward_host}:${host.forward_port} configured`);
		} catch (err) {
			logger.warn(`[${migrateName}] Failed to configure ${host.domain_names.join(", ")}: ${err.message}`);
		}
	}
};

const down = async (knex) => {
	logger.warn(`[${migrateName}] Removing seeded proxy hosts and certificate...`);
	const certificate = await knex("certificate").where({ nice_name: CERT_NICE_NAME }).first();
	if (certificate) {
		await knex("proxy_host").where({ certificate_id: certificate.id }).del();
		await knex("certificate").where({ id: certificate.id }).del();
	}
};

const config = { transaction: false };

export { up, down, config };
