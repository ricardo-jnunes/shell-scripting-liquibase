# global
$libDirectory     = "lib"

# Funcao para baixar as dependencias do Artifactory
Function Get-Dependency($dependency) {
  #'ch.qos.logback:logback-core:1.1.3'
  $dependencyArr = $dependency -split ":"
  $urlG = $dependencyArr[0] -replace "\.", "/"
  $urlA = $dependencyArr[1] -replace "\.", "/"
  $urlV = $dependencyArr[2]
  $url  = "http://localhost:8081/repository/maven-public/$($urlG)/$($urlA)/$($urlV)/$($urlA)-$($urlV).jar"
  $dest = "$($libDirectory)/$($urlA).jar"

  If (-Not (Test-Path $dest)) {
    Write-Warning "Efetuando download de $dependency"
    Import-Module BitsTransfer
    Start-BitsTransfer -Source $url -Destination $dest
  }
}

New-Item $libDirectory -type directory -force | Out-Null

# Obtem as dependencias
Get-Dependency('org.liquibase:liquibase-core:3.5.5')
Get-Dependency('com.microsoft.sqlserver:sqljdbc4:4.0')
Get-Dependency('com.mattbertolini:liquibase-slf4j:2.0.0')
Get-Dependency('org.slf4j:slf4j-api:1.7.13')
Get-Dependency('ch.qos.logback:logback-classic:1.1.3')
Get-Dependency('ch.qos.logback:logback-core:1.1.3')

# Verifica se foi informado o parametro de ambiente
If (-Not ($args[0].StartsWith("--env="))) {
  throw [System.ArgumentException] "Necessario informar o ambiente --env=<ambiente>, devera ser o primeiro parametro.`n   Ex.: database.ps1 --env=hml status"
}

# Verifica se existe o arquivo de configuracao do ambiente
$env = $args[0] -replace "--env=", ""
$configFile = "$($env).properties"
If (-Not (Test-Path config\$configFile)) {
  throw [System.IO.FileNotFoundException] "O arquivo de configuracao $($configFile) nao foi encontrado na pasta config."
}

# Adiciona todos os arquivos encontrados na pasta lib
foreach ($file in get-ChildItem $libDirectory) {
  $classpath += ";$($libDirectory)/$($file.Name)"
}

# Executa o liquibase repassando os parametros
java -Denv="$env" -cp "$classpath" liquibase.integration.commandline.Main --changeLogFile=changelog\changelog-master.xml --defaultsFile=config\$configFile $args[1..($args.length - 1)]
