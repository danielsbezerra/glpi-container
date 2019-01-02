#! /bin/bash

dadosfull() {
cd /var/www/html/
SRCDIR="glpi" #diretórios que serão feito backup
DSTDIR=/var/backups/glpi #diretório de destino do backup
DATA=`date +%Y-%m-%d-%H:%M:%S` # pega data atual
TIME_BKCP=+7 #número de dias em que será deletado o arquivo de backup

##criar o arquivo full-data.tar no diretório de destino
ARQ=$DSTDIR/full-$DATA.tar.gz
##data de inicio backup
DATAIN=`date +%c`
echo "Data de inicio: $DATAIN"
}


#Criar pasta glpi
if [ -e /var/backups/glpi ]
then
  echo "A pasta glpi já existe"
else
  mkdir /var/backups/glpi
  echo "Pasta mysql criada com sucesso"
fi

backupfull(){
sync
tar cvzf $ARQ $SRCDIR
if [ $? -eq 0 ] ; then
  echo "----------------------------------------"
  echo "Backup Full concluído com Sucesso"
  DATAFIN=`date +%c`
  echo "Data de termino: $DATAFIN"
  echo "Backup realizado com sucesso" >> /var/log/backup_full.log
  echo "Criado pelo usuário: $USER" >> /var/log/backup_full.log
  echo "INICIO: $DATAIN" >> /var/log/backup_full.log
  echo "FIM: $DATAFIN" >> /var/log/backup_full.log
  echo "-----------------------------------------" >> /var/log/backup_full.log
  echo " "
  echo "Log gerado em /var/log/backup_full.log"
else
  echo "ERRO! Backup do dia $DATAIN" >> /var/log/backup_full.log
fi
}
 

procuraedestroifull(){
#apagando arquivos mais antigos
find $DSTDIR -name "f*" -ctime $TIME_BKCP -exec rm -f {} ";"
  if [ $? -eq 0 ] ; then
    echo "$DSTDIR -name 'f*' -ctime $TIME_BKCP -exec rm -f {}"
    echo "Arquivo de backup mais antigo eliminado com sucesso!"
  else
    echo "Erro durante a busca e destruição do backup antigo!"
  fi
}


enviabackupremoto(){
# o  diretorio remoto de backup deve esta montado em /mnt/windows_backup e deve ter o diretorio centraldeservicos com permissao de                                                                  escrita dentro dele
# sugestao e montar diretorio com o usuario, senha e dominio contido em  /var/backups/credentials (nao deve ter espaco em branco)
# para montar manualmente
DSTREMOTO=/mnt/windows_backup/centraldeservicos
ARQREMOTO=$DSTREMOTO/backup_centraldeservicos.tar.gz
BDREMOTO=$DSTREMOTO/bd_centraldeservicos.tar.gz
COPY="/usr/bin/cp -f "
if [ ! -d "$DSTREMOTO" ]; then
  mount.cifs //serv26d/BACKUP/ /mnt/windows_backup -o credentials=/var/backups/credentials
  echo "Montei o diretorio $DSTREMOTO"
fi

if [ ! -w "$DSTREMOTO" ] ; then echo 'O Destino remoto nao tem permissao de escrita ou nao esta montado $DSTREMOTO!' >> /var/log/b                                                                 ackup_full.log ; fi
eval "$COPY $ARQ $ARQREMOTO"

if [ ! $? -eq 0 ] ; then echo 'Falha ao copiar backup para o $ARQREMOTO!' >> /var/log/backup_full.log ; fi
eval "$COPY $BD $BDREMOTO"

if [ ! $? -eq 0 ] ; then echo 'Falha ao copiar banco para o $BDREMOTO!' >> /var/log/backup_full.log ; fi
echo "sai"
}


dadosfull
backupfull
procuraedestroifull
procuraedestroibanco
enviabackupremoto


exit 0