package fr.ocelet.datafacer.ocltypes;

import java.io.File;
import java.io.IOException;
import java.util.Iterator;

import org.geotools.data.DataStore;
import org.geotools.data.Query;
import org.geotools.data.shapefile.ShapefileDataStore;
import org.geotools.data.simple.SimpleFeatureSource;
import org.geotools.geometry.jts.ReferencedEnvelope;
import org.opengis.feature.simple.SimpleFeature;
import org.opengis.feature.simple.SimpleFeatureType;
import org.opengis.feature.type.AttributeDescriptor;
import org.opengis.referencing.crs.CoordinateReferenceSystem;

import fr.ocelet.datafacer.InputDataRecord;
import fr.ocelet.datafacer.GtDataRecord;
import fr.ocelet.datafacer.GtDatafacer;
import fr.ocelet.datafacer.InputDatafacer;
import fr.ocelet.datafacer.OcltShapefileDataStore;
import fr.ocelet.datafacer.OutputDataRecord;
import fr.ocelet.datafacer.OutputDatafacer;
import fr.ocelet.runtime.model.AbstractModel;

public abstract class Shapefile extends GtDatafacer implements InputDatafacer,
		OutputDatafacer, Iterator<InputDataRecord> {

	private final String ERR_HEADER = "Datafacer Shapefile: ";
	protected ShapefileDataStore datastore;

	protected File sourceFile;

	/**
	 * If true, overwrite means that existing files with the same name will be
	 * overwritten
	 */
	protected boolean overwrite;

	/**
	 * Constructor initializing the filename and the SRID.
	 * 
	 * @param fileName
	 *            Path and name of a comma separated value file.
	 * @param crs
	 *            The coordinate system in text format. Ex: "EPSG:4326"
	 */
	public Shapefile(String fileName, String epsgcode) {
		super();
		overwrite = true;
		setFileName(AbstractModel.getBasedir() + File.separator + fileName);
		setCrs(epsgcode);
	}

	/**
	 * Initialize and prepares the ShapeFile using the file name given in
	 * argument. The file is not read at this point, but it's availability is
	 * being checked. An error message is printed in case of initialization
	 * problem.
	 * 
	 * This same method is used to create a new Shapefile which is created if
	 * the name given in argument doesn't already exist on the disk.
	 * 
	 * @param shpFileName
	 *            Name of the .shp file
	 */
	public void setFileName(String shpFileName) {
		sourceFile = new File(shpFileName);

		try {
			// Open a datastore that uses our own geometry factory
			datastore = new OcltShapefileDataStore(sourceFile.toURI().toURL());
		} catch (IOException e) {
			System.out.println(ERR_HEADER + "Failed to open the shapefile "
					+ sourceFile);
		}
	}

	/**
	 * If true, overwrite means that existing files with the same name will be
	 * overwritten
	 * 
	 * @return overwrite
	 */
	public Boolean getOverwrite() {
		return overwrite;
	}

	/**
	 * If true, overwrite means that existing files with the same name will be
	 * overwritten
	 * 
	 * @param ov The new overwrite value
	 */
	public void setOverwrite(Boolean ov) {
		this.overwrite = ov;
	}

	/**
	 * @return A short symbolic name for this data set
	 */
	@Override
	public String getName() {
		return sourceFile.getName();
	}

	/**
	 * Returns the name of this Shapefile
	 */
	@Override
	public String toString() {
		return getName();
	}

	/**
	 * Creates a new empty datarecord.
	 * 
	 * @return An OutputDataRecord with no attribute initialization
	 */
	@Override
	public OutputDataRecord createOutputDataRec() {
		OutputDataRecord odr = null;
		try {
			odr = new ShapefileDataRec(createFeature(getSimpleFeatureType()));
		} catch (IOException e) {
			System.out
					.println(getErrHeader()
							+ " Failed to create a record before writing to the datafacer. Please check the datafacer declaration.");
			return null;
		}
		return odr;
	}

	/**
	 * @return A complete description of everything we know about this Shapefile
	 * @deprecated Use about() instead
	 */
	public String getMetadata() {
		return about();
	}

	/**
	 * @return A complete description of everything we know about this Shapefile
	 */
	public String about() {
		StringBuffer sb = new StringBuffer();
		try {
			SimpleFeatureType sft = datastore.getSchema();
			sb.append("Shapefile : " + sft.getTypeName() + "\n");
			sb.append("  Contains " + getFeatureSource().getCount(new Query())
					+ " records. \n");
			CoordinateReferenceSystem crs = sft.getCoordinateReferenceSystem();
			if (crs != null)
				sb.append("  Coordinate reference system : " + crs.getName()
						+ "\n");
			ReferencedEnvelope bounds = getFeatureSource().getBounds();
			sb.append("  Bounds : " + bounds.getMinX() + " " + bounds.getMinY()
					+ " , " + bounds.getMaxX() + " " + bounds.getMaxY() + " \n");

			int nbat = sft.getAttributeCount();
			if (nbat == 1)
				sb.append("  Description of the only attribute :" + "\n");
			else
				sb.append("  Description of the " + nbat + " attributes :"
						+ "\n");
			int adx = 0;
			for (AttributeDescriptor ad : sft.getAttributeDescriptors())
				sb.append("   [" + (1 + adx++) + "] : " + ad.getName()
						+ " : \t" + ad.getType().getBinding().getSimpleName()
						+ "\n");
		} catch (IOException e) {
			System.out.println(ERR_HEADER + "Failed to open the shapefile "
					+ sourceFile);
		} catch (NullPointerException e) {
			System.out.println(ERR_HEADER + "Failed to open the shapefile "
					+ sourceFile);
		}
		return sb.toString();
	}

	/**
	 * Reads and displays this ShapeFile in a window
	 * 
	 * public void view() { MapContext map = new DefaultMapContext();
	 * map.setTitle("Shape file viewer"); map.addLayer(featureSource, null);
	 * JMapFrame.showMap(map); }
	 */

	@Override
	public Iterator<InputDataRecord> iterator() {
		return this;
	}

	/**
	 * Checks if there is any more record that has not yet been read
	 * 
	 * @return true is there are more records to be read
	 */
	@Override
	public boolean hasNext() {
		if (sfiterator == null) {
			try {
				if (featureCollection == null) {
					if (getFeatureSource() != null)
						featureCollection = getFeatureSource().getFeatures();
					else
						return false;
				}
				sfiterator = featureCollection.features();
			} catch (IOException e) {
				System.out
						.println(ERR_HEADER
								+ "Problem while attempting to read the shapefile's content.");
			}
		}
		return sfiterator.hasNext();
	}

	/**
	 * Returns the next record read from the file.
	 * 
	 * @return A line String
	 */
	public GtDataRecord next() {
		GtDataRecord nextRecord = null;
		if (hasNext()) {
			SimpleFeature feature = sfiterator.next();
			nextRecord = new ShapefileDataRec(feature);
			lastRead = nextRecord;
		} else {
			sfiterator.close();
			sfiterator = null;
		}
		return nextRecord;
	}

	@Override
	public void remove() {
	}

	@Override
	public GtDataRecord getLastRead() {
		return this.lastRead;
	}

	@Override
	public String getErrHeader() {
		return this.ERR_HEADER;
	}

	@Override
	public SimpleFeatureSource getFeatureSource() throws IOException {
		return datastore.getFeatureSource(datastore.getTypeNames()[0]);
	}

	/**
	 * @return The DataStore of this Datafacer
	 */
	@Override
	public DataStore getDataStore() {
		return datastore;
	}

	@Override
	public void close() {
		datastore.dispose();
	}

}
