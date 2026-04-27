<?php
declare(strict_types=1);
?>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<title>PHP + SQL Server — Docker</title>
<style>
  body { font-family: sans-serif; max-width: 800px; margin: 40px auto; padding: 0 20px; background: #0f172a; color: #e2e8f0; }
  h1   { color: #38bdf8; }
  .card { background: #1e293b; border-radius: 8px; padding: 20px; margin: 16px 0; }
  .ok  { color: #4ade80; } .err { color: #f87171; }
  table { width: 100%; border-collapse: collapse; }
  td, th { padding: 8px 12px; border: 1px solid #334155; text-align: left; }
  th { background: #0f172a; color: #94a3b8; }
</style>
</head>
<body>
<h1>PHP + SQL Server — Docker</h1>

<div class="card">
  <h2>Estado del entorno</h2>
  <table>
    <tr><th>Componente</th><th>Estado</th></tr>
    <tr><td>PHP</td><td class="ok"><?= PHP_VERSION ?></td></tr>
    <tr><td>SAPI</td><td><?= PHP_SAPI ?></td></tr>
    <tr>
      <td>sqlsrv</td>
      <td class="<?= extension_loaded('sqlsrv') ? 'ok' : 'err' ?>">
        <?= extension_loaded('sqlsrv') ? '&#10003; cargado' : '&#10007; ausente' ?>
      </td>
    </tr>
    <tr>
      <td>pdo_sqlsrv</td>
      <td class="<?= extension_loaded('pdo_sqlsrv') ? 'ok' : 'err' ?>">
        <?= extension_loaded('pdo_sqlsrv') ? '&#10003; cargado' : '&#10007; ausente' ?>
      </td>
    </tr>
    <tr>
      <td>mbstring</td>
      <td class="<?= extension_loaded('mbstring') ? 'ok' : 'err' ?>">
        <?= extension_loaded('mbstring') ? '&#10003; cargado' : '&#10007; ausente' ?>
      </td>
    </tr>
    <tr>
      <td>opcache</td>
      <td class="<?= extension_loaded('opcache') ? 'ok' : 'err' ?>">
        <?= extension_loaded('opcache') ? '&#10003; cargado' : '&#10007; ausente' ?>
      </td>
    </tr>
  </table>
</div>

<div class="card">
  <h2>Ejemplo de conexión PDO — SQL Server</h2>
  <pre style="background:#0f172a;padding:12px;border-radius:6px;overflow:auto">$pdo = new PDO(
    "sqlsrv:Server=MI_SERVIDOR,1433;Database=MI_BASE",
    "usuario",
    "password"
);</pre>
</div>

<details>
  <summary style="cursor:pointer;color:#38bdf8;margin-top:20px">Ver phpinfo()</summary>
  <?php
    ob_start();
    phpinfo();
    $info = ob_get_clean();
    $info = preg_replace('%^.*<body>(.*)</body>.*$%ms', '$1', $info);
    echo $info;
  ?>
</details>
</body>
</html>
